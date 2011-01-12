require.paths.unshift("/puppy/lib/node")

exec      = require("child_process").exec
syslog    = new (require("common/syslog").Syslog)({ tag: "account_activate", pid: true })
shell     = new (require("common/shell").Shell)(syslog)
db        = require("common/database")

argv      = process.argv.slice 2
hostname  = argv.shift()

db.createDatabase syslog, (database) ->
  process.stdout.write "Hello, World!\n"
