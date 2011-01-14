require.paths.unshift("/puppy/lib/node")

exec      = require("child_process").exec
syslog    = new (require("common/syslog").Syslog)({ tag: "account_activate", pid: true })
shell     = new (require("common/shell").Shell)(syslog)
db        = require("common/database")

argv          = process.argv.slice 2
applicationId = argv.shift()

db.createDatabase syslog, (database) ->
  uid = parseInt process.env["SUDO_UID"], 10
  shell.verify(uid > 10000, "Inexplicable uid #{uid}")
  shell.hostname (hostname) ->
    database.select "getAccountByLocalUser", [ hostname, uid ], "account", (results) ->
      account = results.shift()
      database.select "getApplicationLocalUsers", [ applicationId ], "localUser", (results) ->
        for localUser in results
          shell.verify(localUser.application.account.id is account.id,
                "User attempted to fetch a port for application of another user.")
          database.fetchLocalPort localUser.machineId, localUser.id, 1, (localUser) ->
            process.stdout.write "Assigned port to application t#{applicationId}.\n"
