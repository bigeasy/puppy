require.paths.unshift("/puppy/lib/node")

exec      = require("child_process").exec
syslog    = new (require("common/syslog").Syslog)({ tag: "account_activate", pid: true })
shell     = new (require("common/shell").Shell)(syslog)
db        = require("common/database")

argv      = process.argv.slice 2
appId     = argv.shift()

db.createDatabase syslog, (database) ->
  database.select "getApplicationLocalUsers", [ appId ], "localUser", (results) ->
    for localUser in results
      process.stdout.write "#{localUser.machine.hostname} #{localUser.id}\n"
