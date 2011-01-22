fs            = require "fs"
Client        = require("mysql").Client
exec          = require("child_process").exec
spawn         = require("child_process").spawn
Danger        = require("common/danger").Danger

module.exports.createDatabase = (syslog, callback) ->
  shell = new (require("common/shell").Shell)(syslog)
  shell.doas "database", "/puppy/bin/database", [], null, (stdout) ->
    callback(new Database(stdout.substring 0, 32))

class Database
  constructor: (@password) ->
    @queries = {}
    for file in fs.readdirSync __dirname + "/../queries"
      @queries[file] = fs.readFileSync __dirname + "/../queries/" + file , "utf8"

  createClient: ->
    client            = new Client()
    client.user       = "puppy"
    client.password   = @password
    client.database   = "puppy"

    client

  select: (query, parameters, get, callback) ->
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
    exec "/bin/hostname", (error, stdout) =>
      throw error if error
      hostname = stdout.substring(0, stdout.length - 1)
      @select "getLocalUserAccount", [ hostname, localUserId ], "account", (results) ->
        callback(results.shift())

  fetchLocalPort: (machineId, localUserId, service, callback) ->
    @select "fetchLocalPort", [ localUserId, service, machineId ], (results) =>
      if results.affectedRows is 0
        @createLocalPort machineId, localUserId, service, callback
      else
        @select "getLocalPortByAssignment", [ results.insertId ], "localPort", (results) ->
          callback(results.shift())

  createLocalPort: (machineId, localUserId, service, callback) ->
    @select "nextLocalPort", [ machineId ], (results) =>
      nextLocalPort = results[0].nextLocalPort
      @error = (error) =>
        throw error if error.number isnt 1062
        @createLocalPort machineId, localUserId, service, callback
      @select "insertLocalPort", [ machineId, nextLocalPort ], (results) =>
        @fetchLocalPort machineId, localUserId, service, callback

  fetchLocalUser: (applicationId, callback) ->
    @select "getMachines", [], "machine", (results) =>
      machine = results[0]
      @error = (error) =>
        throw error if error.number isnt 1062
        @fetchLocalUser applicationId, callback
      @select "fetchLocalUser", [ applicationId, machine.id ], (results) =>
        if results.affectedRows is 0
          @createLocalUser applicationId, machine.id, callback
        else
          @select "getLocalUserByAssignment", [ results.insertId ], "localUser", (results) ->
            callback(results.shift())

  createLocalUser: (applicationId, machineId, callback) ->
    @select "nextLocalUser", [ machineId ], (results) =>
      nextLocalUserId = results[0].nextLocalUserId
      @error = (error) =>
        throw error if error.number isnt 1062
        @createLocalUser applicationId, machineId, callback
      @select "insertLocalUser", [ machineId, nextLocalUserId ], (results) =>
        @fetchLocalUser applicationId, callback

  enqueue: (hostname, commands, callback) ->
    if commands.length
      @select "insertJob", [ JSON.stringify(commands.shift()), hostname ], (results) =>
        @enqueue(hostname, commands, callback)
    else if callback
      callback()
