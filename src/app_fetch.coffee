class Application
  fetchApplication: (accountId, callback) ->
    database = new Database()
    database.select "insertApplication", [ accountId ], (results) =>
      database.select "getApplication", [ results.insertId ], "application", (results) =>
        application = results[0]
        database.select "getMachines", [], "machine", (results) =>
          machine = results[0]
          database.select "fetchLocalUser", [ application.id, machine.id ], (results) =>
            console.log results
            if results.affectedRows is 0
              console.log "Must create a new local user."
              @createLocalUser application, machine, () =>
            else
              callback(application)

  createLocalUser: (application, machine, callback) ->
    database = new Database()
    database.select "nextLocalUser", [ machine.id ], (results) =>
      nextLocalUserId = results[0].nextLocalUserId
      client = database.createClient()
      client.connect =>
        console.log machine
        client.query database.queries["insertLocalUser"], [ machine.id, nextLocalUserId ], (error, results, fields) =>
          client.end()
          if error
            if error.number is 1062
              @createLocalUser application, machine, callback
            else
              throw error
          else
            systemId = nextLocalUserId + 10000
            @script "/bin/bash", "-e", """
            /usr/sbin/groupadd --gid #{systemId}  u#{systemId}
            /usr/sbin/useradd --gid #{systemId} --uid #{systemId} --home-dir /home/u#{systemId} u#{systemId}
            """, (error, stdout, stderr) =>
              if error != 0
                console.log error
                throw new Error("Cannot create user.")
              callback(application)

application = new Application()
module.exports.command =
  fetch: (argv) ->
    application.fetchApplication argv.shift(), ->
