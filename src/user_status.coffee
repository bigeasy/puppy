syslog    = new (require("common/syslog").Syslog)({ tag: "user_status", pid: true })
shell     = new (require("common/shell").Shell)(syslog)
exec      = require("child_process").exec

db        = require("common/database")

module.exports.command = (argv) ->
  hostname = argv.shift()
  id = parseInt argv.shift(), 10
  db.createDatabase syslog, (database) ->
    database.select "getLocalUser", [ id, hostname ], "localUser", (results) ->
      if results.length is 0
        process.exit 1
      localUser = results.shift()
      process.stdout.write("#{localUser.status}\n")
