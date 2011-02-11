require.paths.unshift("/puppy/lib/node")

exec      = require("child_process").exec
syslog    = new (require("common/syslog").Syslog)({ tag: "account_activate", pid: true })
shell     = new (require("common/shell").Shell)(syslog)
db        = require("common/database")

argv      = process.argv.slice 2

db.createDatabase syslog, (database) ->
  uid = parseInt process.env["SUDO_UID"], 10
  shell.verify(uid > 10000, "Inexplicable uid #{uid}")
  shell.hostname (hostname) ->
    database.select "getAccountByLocalUser", [ hostname, uid ], "account", (results) ->
      account = results.shift()
      database.select "insertApplication", [ account.id, 0 ], (results) ->
        applicationId = results.insertId
        database.select "getMachines", [], "machine", (results) ->
          machine = results[0]
          database.select "fetchLocalUser", [ applicationId, machine.id, 1 ], (results) =>
            if results.affectedRows
              database.select "getLocalUserByAssignment", [ results.insertId ], "localUser", (results) ->
                localUser = results.shift()
                database.enqueue localUser.machine.hostname, [
                  [ "user:create", [ localUser.id ] ],
                  [ "user:restorecon", [ localUser.id ] ],
                  [ "user:decommission", [ localUser.id ] ],
                  [ "user:provision", [ localUser.id ] ],
                  [ "user:restorecon", [ localUser.id ] ],
                  [ "user:skel", [ localUser.id, "protected" ] ],
                  [ "user:authorize", [ localUser.id ] ],
                  [ "user:config", [ localUser.id ] ],
                  [ "user:restorecon", [ localUser.id ] ],
                  [ "user:group", [ localUser.id, "protected" ] ],
                  [ "user:chown", [ localUser.id ] ]
                  [ "init:generate", [ localUser.id ] ]
                  [ "init:restorecon", [ localUser.id ] ]
                ], ->
                  database.select "getLocalPorts", [ localUser.machine.hostname, localUser.id ], "localPort", (localPorts) ->
                    localPort = localPorts.shift()
                    database.virtualHost "t#{applicationId}.portoroz.runpup.com", localUser.machine.ip,  localPort.port, ->
                      process.stdout.write "Application t#{applicationId} created.\n"
            else
              syslog.error "Unable to allocate local user account for application #{applicationId}."
              process.stdout.write "Unable to allocate application."
              process.exit 1
