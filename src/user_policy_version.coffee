# Prepend the puppy library directory to the path.
require.paths.unshift("/puppy/lib/node")

# Import Puppy libraries.
syslog    = new (require("common/syslog").Syslog)({ tag: "user_policy_version", pid: true })
shell     = new (require("common/shell").Shell)(syslog)
db        = require("common/database")

# Read command line arguments, hostname and user id.
argv      = process.argv.slice(2)
hostname  = argv.shift()
id        = parseInt argv.shift(), 10

db.createDatabase syslog, (database) ->
  if argv.length
    version = argv.shift()
    database.select "setLocalUserPolicyVersion", [ version, hostname, id ], (results) ->
      if results.affectedRows != 1
        syslog.send "err", "ERROR: Cannot set policy version of uid #{id} on machine #{hostname}."
        process.exit 1
  else
    database.select "getLocalUser", [ hostname, id ], "localUser", (results) ->
      if results.length is 0
        syslog.send "err", "ERROR: Cannot find uid #{id} on machine #{hostname}."
        process.exit 1
      localUser = results.shift()
      process.stdout.write("#{localUser.policy}\n")
