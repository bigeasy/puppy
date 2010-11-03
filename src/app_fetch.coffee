shell     = new (require("puppy/shell").Shell)()
database  = new (require("puppy/database").Database)()
protected = require("./protected")
fs        = require "fs"
exec      = require("child_process").exec

module.exports.command = (bin, argv) ->
  fetch = (file, callback) ->
    command = protected.command(file)
    database.getLocalUserAccount command.uid - 10000, (account) =>
      fetchApplication account.id, callback

  fetchApplication = (accountId, callback) ->
    database.select "insertApplication", [ accountId ], (results) ->
      database.select "getApplication", [ results.insertId ], "application", (results) ->
        application = results[0]
        database.select "getMachines", [], "machine", (results) ->
          machine = results[0]
          database.select "fetchLocalUser", [ application.id, machine.id ], (results) ->
            console.log results
            if results.affectedRows is 0
              console.log "Must create a new local user."
              createLocalUser application, machine, () ->
            else
              callback(application)

  createLocalUser = (application, machine, callback) ->
    database.select "nextLocalUser", [ machine.id ], (results) ->
      nextLocalUserId = results[0].nextLocalUserId
      client = database.createClient()
      client.connect =>
        console.log machine
        client.query database.queries["insertLocalUser"], [ machine.id, nextLocalUserId ], (error, results, fields) =>
          client.end()
          if error
            if error.number is 1062
              createLocalUser application, machine, callback
            else
              throw error
          else
            console.log "MUST CREATE USER"

  fetch argv[0], ->
    console.log "DONE"
