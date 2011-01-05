# Prepend the puppy library directory to the path.
require.paths.unshift("/puppy/lib/node")

# Import Puppy libraries.
syslog    = new (require("common/syslog").Syslog)({ tag: "policy_version", pid: true })
shell     = new (require("common/shell").Shell)(syslog)
db        = require("common/database")

# Read command line arguments, hostname and user id.
argv      = process.argv.slice(2)
hostname  = argv.shift()
id        = parseInt argv.shift(), 10

db.createDatabase syslog, (database) ->
  database.select "getPolicyVersion", [ hostname ], (results) ->
    process.stdout.write "#{results[0].version}\n"
