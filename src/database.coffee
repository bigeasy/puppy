fs            = require "fs"
Client        = require("mysql").Client
exec          = require("child_process").exec
Danger        = require("common/danger").Danger

module.exports.Database = class Database
  constructor: () ->
    @queries = {}
    for file in fs.readdirSync __dirname + "/../queries"
      @queries[file] = fs.readFileSync __dirname + "/../queries/" + file , "utf8"
    @password = fs.readFileSync "/etc/puppy/database/password", "utf8"
    @password = @password.substring 0, @password.length - 1

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
      if error
        danger = new Danger("ERROR: MySQL is not available.", { e: error.message })
        process.stdout.write danger.toString()
        process.exit 1
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

  fetchLocalPort: (applicationId, machineId, service, callback) ->
    @select "fetchLocalPort", [ applicationId, machineId, service ], (results) =>
      console.log results
      if results.affectedRows is 0
        @createLocalPort applicationId, machineId, service, callback
      else
        @select "getLocalPortByAssignment", [ results.insertId ], "localPort", (results) ->
          callback(results.shift())

  createLocalPort: (applicationId, machineId, service, callback) ->
    @select "nextLocalPort", [ machineId ], (results) =>
      nextLocalPort = results[0].nextLocalPort
      @error = (error) =>
        throw error if error.number isnt 1062
        @createLocalPort applicationId, machineId, callback
      @select "insertLocalPort", [ machineId, nextLocalPort ], (results) =>
        @fetchLocalPort applicationId, machineId, service, callback

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
