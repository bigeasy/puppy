require.paths.unshift("/puppy/common/lib/node")

syslog    = new (require("common/syslog").Syslog)({ tag: "account_activate", pid: true })
shell     = new (require("common/shell").Shell)(syslog)
db        = require("common/database")

db.createDatabase syslog, (database) ->
  uid = parseInt process.env["SUDO_UID"], 10
  shell.verify(uid > 10000 and uid < 20000, "Inexplicable uid #{uid}")
  shell.hostname (hostname) ->
    database.select "getApplicationByLocalUser", [ hostname, uid ], "application", (applications) ->
      application = applications.shift()
      database.select "getApplicationLocalUsers", [ application.id ], "localUser", (localUsers) ->
        for localUser in localUsers
          if localUser.machine.hostname is hostname and localUser.id is uid
            database.enqueue localUser.machine.hostname, [
                [ "daemon:stop", [ localUser.id ] ]
                [ "user:deploy", [ localUser.id ] ]
                [ "daemon:start", [ localUser.id ] ]
            ]
