require.paths.unshift("/puppy/common/lib/node")

syslog    = new (require("common/syslog").Syslog)({ tag: "app_list", pid: true })
shell     = new (require("common/shell").Shell)(syslog)
db        = require("common/database")

db.createDatabase syslog, (database) ->
  uid = parseInt process.env["SUDO_UID"], 10
  shell.verify(uid > 10000, "Inexplicable uid #{uid}")
  shell.hostname (hostname) ->
    database.select "getAccountByLocalUser", [ hostname, uid ], "account", (accounts) ->
      shell.verify(accounts.length, "Unknown uid #{uid} on #{hostname}.")
      account = accounts.shift()
      database.select "getApplications", [ account.id ], "application", (applications) ->
        for application in applications
          application.status = if application.ready is 1 then "ready" else "pending"
        process.stdout.write JSON.stringify({
          error: false
          applications
        })
