require.paths.unshift("/puppy/lib/node")

exec      = require("child_process").exec
syslog    = new (require("common/syslog").Syslog)({ tag: "account_activate", pid: true })
shell     = new (require("common/shell").Shell)(syslog)
db        = require("common/database")

argv      = process.argv.slice 2
hostname  = argv.shift()

db.createDatabase syslog, (database) ->
  uid = parseInt process.env["SUDO_UID"], 10
  shell.verify(uid > 10000, "Inexplicable uid #{uid}")
  database.select "getAccountByLocalUser", [ hostname, uid ], "account", (results) ->
    account = results.shift()
    database.select "insertApplication", [ account.id, 0 ], (results) ->
      applicationId = results.insertId
      database.fetchLocalUser applicationId, (localUser) ->
        shell.enqueue localUser.machine.hostname,
          [ "user:create", [ localUser.id ] ],
          [ "user:restorecon", [ localUser.id ] ],
          [ "user:decommission", [ localUser.id ] ],
          [ "user:provision", [ localUser.id ] ],
          [ "user:restorecon", [ localUser.id ] ],
          [ "user:skel", [ localUser.id ] ],
          [ "user:authorize", [ localUser.id ] ],
          [ "user:restorecon", [ localUser.id ] ],
          [ "user:group", [ localUser.id, "protected" ] ],
          [ "user:chown", [ localUser.id ] ]
        process.stdout.write "Application t#{applicationId} created.\n"
