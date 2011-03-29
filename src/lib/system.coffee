fs            = require "fs"
Client        = require("mysql").Client
spawn         = require("child_process").spawn

# The system can only be created once in the life of a program.
systemCreated = false

collections = {}
for property in "hostname, account, uid, application".split /,\s/
  do (property) ->
    collections[property] = (system, next) ->
      system[property].apply system, [ ((value) ->
        next(value)
      ) ]

module.exports.createSystem = (filename, splat...) ->
  # Assert that the system has not already been created.
  if systemCreated
    throw new Error("System has already been created.")
  systemCreated = true

  additional = if splat.length is 2 then splat.shift().split(/,\s*/) else []
  callback = splat.shift()

  require("common").createShell filename, (shell) ->
    shell.doas "database", "/puppy/database/bin/database", [], null, (stdout) ->
      {host, password} = JSON.parse(stdout)
      system = new System(shell.syslog, shell, host, password)
      index = 0
      parameters = []
      argv = null
      next = (parameter) ->
        parameters.push parameter
        if index == additional.length
          callback.apply null, parameters
        else
          property = additional[index++]
          if collections[property]
            collections[property](system, next)
          else
            unless argv?
              system.argv = {}
              argv = {}
              if process.argv.length % 2 is 0
                i = 2
                while i < process.argv.length
                  if /^--/.test(process.argv[i])
                    argv[process.argv[i]] = process.argv[i + 1]
                  else
                    argv = {}
                    break
                  i += 2
            pair = property.split /\s+or\s+/
            next(system.argv[pair[0]] = argv["--#{pair[0]}"] or (pair[1] and (JSON.parse("[#{pair[1]}]"))[0]))
      next(system)

class System
  constructor: (@syslog, @shell, @host, @password) ->
    @queries = {}
    for file in fs.readdirSync __dirname + "/../queries"
      @queries[file] = fs.readFileSync __dirname + "/../queries/" + file , "utf8"

  createClient: ->
    client            = new Client()
    client.host       = @host
    client.user       = "puppy"
    client.password   = @password
    client.database   = "puppy"

    client

  sql: (query, parameters, get, callback) ->
    if typeof get is "function"
      callback = get
      get = null
    client = @createClient()
    client.on "error", -> process.stdout.write "ERROR: MySQL Missing."
    client.connect (error) =>
      throw error if error
      client.on "end", -> client.destroy()
      client.query @queries[query], parameters, (error, results, fields) =>
        client.end -> client.destroy()
        if error
          if @error
            @error(error, this)
            @error = null
          else
            throw error
        else
          @error = null
          if get
            expanded = []
            for result in results
              expanded.push @treeify result, get
          else
            expanded = results
          callback expanded, fields

  treeify: (record, get) ->
    tree = {}
    for key, value of record
      parts = key.split /__/
      branch = tree
      for i in [0...parts.length - 1]
        branch = branch[parts[i]] = branch[parts[i]] or {}
      branch[parts[parts.length - 1]] = record[key]
    tree[get]

  getLocalUserAccount: (localUserId, callback) ->
    @hostname (hostname) =>
      @sql "getLocalUserAccount", [ hostname, localUserId ], "account", (results) ->
        callback(results.shift())

  fetchLocalPort: (machineId, localUserId, service, callback) ->
    @sql "fetchLocalPort", [ localUserId, service, machineId ], (results) =>
      if results.affectedRows is 0
        @createLocalPort machineId, localUserId, service, callback
      else
        @sql "getLocalPortByAssignment", [ results.insertId ], "localPort", (results) ->
          callback(results.shift())

  createLocalPort: (machineId, localUserId, service, callback) ->
    @sql "nextLocalPort", [ machineId ], (results) =>
      nextLocalPort = results[0].nextLocalPort
      @error = (error) =>
        throw error if error.number isnt 1062
        @createLocalPort machineId, localUserId, service, callback
      @sql "insertLocalPort", [ machineId, nextLocalPort ], (results) =>
        @fetchLocalPort machineId, localUserId, service, callback

  fetchLocalUser: (applicationId, callback) ->
    @sql "getMachines", [], "machine", (results) =>
      machine = results[0]
      @error = (error) =>
        throw error if error.number isnt 1062
        @fetchLocalUser applicationId, callback
      @sql "fetchLocalUser", [ applicationId, machine.id, 0 ], (results) =>
        if results.affectedRows is 0
          @createLocalUser applicationId, machine.id, callback
        else
          @sql "getLocalUserByAssignment", [ results.insertId ], "localUser", (results) ->
            callback(results.shift())

  createLocalUser: (applicationId, machineId, callback) ->
    @sql "nextLocalUser", [ machineId, 9999999999 ], (results) =>
      nextLocalUserId = results[0].nextLocalUserId
      @error = (error) =>
        throw error if error.number isnt 1062
        @createLocalUser applicationId, machineId, callback
      @sql "insertLocalUser", [ machineId, nextLocalUserId, 0, 1 ], (results) =>
        @fetchLocalUser applicationId, callback

  enqueue: (hostname, commands, callback) ->
    if commands.length
      command = commands.shift()
      @sql "insertJob", [ JSON.stringify(command), hostname ], (results) =>
        @syslog.send "info", "Enqueued command #{command[0]}.", { command }
        @enqueue(hostname, commands, callback)
    else if callback
      callback()

  properties: (callback) ->
    @sql "properties", [], (results) =>
      properties = {}
      for property in results
        properties[property.name] = property.value
      callback(properties)

  virtualHost: (name, ip, port, callback) ->
    @sql "deleteVirtualHost", [ name ], (results) =>
      @sql "insertVirtualHost", [ name, ip, port ], (results) =>
        if results.affectedRows is 0
          throw new Error("Unable to insert virtual host #{name}.")
        callback()

  err: (message, context) ->
    @shell.err message, context

  verify: (condition, message, context) ->
    unless condition
      throw new Error @shell.err message, context

  # Get the application by application id, verifying that it is associated with
  # the machine user of the sudoer that invoked the current program.
  #
  # This method is invoked by programs run by an end user via `sudo`.
  #
  # FIXME: This is called by db_list and db_fetch, but we should always only ssh
  # to an account of the application of interest. Or should we? That would be a
  # single point of failure.
  application: (callback) ->
    @hostname (hostname) =>
      uid = @uid()
      if @argv?.applicationId?
        @sql "getApplicationByIdAndLocalUser", [ @argv.applicationId, hostname, uid ], "application", (applications) =>
          @verify applications.length, "No such application t#{@argv.applicationId} for u#{uid} on #{hostname}."
          callback(applications.shift())
      else
        @sql "getApplicationByLocalUser", [ hostname, uid ], "application", (applications) =>
          @verify applications.length, "No such application for u#{uid} on #{hostname}."
          callback(applications.shift())

  hostname: (callback) ->
    if @_hostname
      callback(@_hostname)
    else
      # FIXME Put this all in shell.
      hostname = spawn "/bin/hostname"
      stdout = ""
      stderr = ""
      hostname.stderr.on "data", (data) -> stderr += data.toString()
      hostname.stdout.on "data", (data) -> stdout += data.toString()
      hostname.on "exit", (code) =>
        if code != 0
          throw new Error @err "Unable to execute hostname.", { code, stderr, stdout }
        callback(@_hostname = stdout.substring(0, stdout.length - 1))

  uid: (callback) ->
    # Check that the uid is sane.
    uid = parseInt process.env["SUDO_UID"], 10
    @verify uid > 10000, "Inexplicable uid #{uid}"
    callack(uid) if callback?
    uid

  account: (callback) ->
    if @_account
      callback(@_account)
    else
      uid = @uid()
      # Get hostname in order to get the account by hostname and local user.
      @hostname (hostname) =>
        # Get the account for the local user. The verify will always be true in this
        # case, but we do it anyway out of habit. If not we'd have to explain here
        # why we didn't, so it's easy to to just do it.
        @sql "getAccountByLocalUser", [ hostname, uid ], "account", (accounts) =>
          @verify accounts.length, "No account for u#{uid} on #{hostname}."
          callback(@_account = accounts.shift())
