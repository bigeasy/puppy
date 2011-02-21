require.paths.unshift("/puppy/common/lib/node")

syslog    = new (require("common/syslog").Syslog)({ tag: "user_activation", pid: true })
shell     = new (require("common/shell").Shell)(syslog)

db        = require("common/database")

argv      = process.argv.slice(2)
email     = argv.shift()

db.createDatabase syslog, (database) ->
  database.select "getActivationByEmail", [ email ], "activation", (results) ->
    if results.length is 0
      syslog.send "err", "ERROR: Cannot find activation for email #{email}."
      process.exit 1
    process.stdout.write("#{JSON.stringify(results.shift())}\n")
