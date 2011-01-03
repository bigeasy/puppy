require.paths.unshift("/puppy/lib/node")

syslog    = new (require("common/syslog").Syslog)({ tag: "user_provisioned", pid: true })
shell     = new (require("common/shell").Shell)(syslog)

db        = require("common/database")

argv      = process.argv.slice(2)
hostname  = argv.shift()
id        = parseInt argv.shift(), 10

db.createDatabase syslog, (database) ->
  database.select "getLocalUser", [ hostname, id ], "localUser", (results) ->
    if results.length is 0
      syslog.send "err", "ERROR: Cannot find user u#{id + 10000} on #{hostname}"
      process.exit 1
    localUser = results.shift()
    if localUser.status isnt 0
      syslog.send "err", "ERROR: User u#{id + 10000} on #{hostname} is provisioned already."
      process.exit 1
    database.select "setLocalUserStatus", [ 1, hostname, id ], (results) ->
