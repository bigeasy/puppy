fs            = require "fs"
pg            = require "pg"
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
      databaseUrl = stdout.replace /\n/, ''
      system = new System(shell.syslog, shell, databaseUrl)
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

class Database
  constructor: (@system, @client, @queries) ->

  sql: (query, parameters, get, callback) ->
    if typeof get is "function"
      callback = get
      get = null
    @client.query @queries[query], parameters, (error, results) =>
      expanded = results
      if not error
        if get
          expanded = []
          for result in results
            expanded.push @treeify result, get
        else
          expanded = results
      callback(error, expanded)

  close: -> @client.end()

  treeify: (record, get) ->
    tree = {}
    for key, value of record
      parts = key.split /__/
      branch = tree
      for i in [0...parts.length - 1]
        branch = branch[parts[i]] = branch[parts[i]] or {}
      branch[parts[parts.length - 1]] = record[key]
    tree[get]

class System
  constructor: (@syslog, @shell, @databaseUrl) ->
    @queries = {}
    for file in fs.readdirSync __dirname + "/../queries"
      @queries[file.replace(/\.sql$/, "")] = fs.readFileSync __dirname + "/../queries/" + file , "utf8"

  database: (callback) ->
    console.log @databaseUrl
    client = new (pg.Client)(@databaseUrl)
    client.on "connect", =>
      database = new Database(this, client, @queries)
      callback(null, database)
    client.on "error", (error) =>
      callback(error, null)
    client.connect()
    
  # This will create a lot of connections, but not too many, really. Most
  # scripts run a single query anyway, so saving the connection is not going to
  # be a huge performance gain. For daemons, yes, manage the connection
  # directly, but for scripts this is good enough, and we know for sure that
  # we're not going to hang on an open socket.
  sql: (query, parameters, get, callback) ->
    if typeof get is "function"
      callback = get
      get = null
    @database (error, database) =>
      if error
        throw new Error @err "Unable to connect to MySQL: #{error.message}", { error }
      database.sql query, parameters, get, (error, results) =>
        database.close()
        if error
          throw new Error @err "Unable to perform query: #{error.message}", { error }
        callback(results)

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
    callback(uid) if callback?
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
