require.paths.unshift("/puppy/common/lib/node")

syslog    = new (require("common/syslog").Syslog)({ tag: "app_user_ready", pid: true })
shell     = new (require("common/shell").Shell)(syslog)
db        = require("common/database")

argv = process.argv.slice 2

accountId = argv.shift()

db.createDatabase syslog, (database) ->
  database.select "setAccountReady", [ accountId ], (results) ->
    shell.verify(results.affectedRows is 1, "Unable to mark account #{accountId} ready.")
