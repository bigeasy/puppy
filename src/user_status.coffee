# Prepend the puppy library directory to the path.
require.paths.unshift("/puppy/lib/node")

# Import Puppy libraries.
syslog    = new (require("common/syslog").Syslog)({ tag: "user_status", pid: true })
shell     = new (require("common/shell").Shell)(syslog)
db        = require("common/database")

# Read command line arguments, hostname and user id.
argv      = process.argv.slice(2)
hostname  = argv.shift()
id        = parseInt argv.shift(), 10

db.createDatabase syslog, (database) ->
  if argv.length is 0
    database.select "getLocalUser", [ hostname, id ], "localUser", (results) ->
      if results.length is 0
        syslog.send "err", "ERROR: Cannot find user u#{id + 10000} on #{hostname}."
        process.exit 1
      localUser = results.shift()
      process.stdout.write("#{localUser.status}\n")
  else
    status = argv.shift()
    database.select "setLocalUserStatus", [ status, hostname, id ], (results) ->
      if results.affectedRows is 0
        syslog.send "err", "ERROR: Cannot find user u#{id + 10000} on #{hostname}."
        process.exit 1