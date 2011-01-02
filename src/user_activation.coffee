require.paths.unshift("/puppy/lib/node")

syslog    = new (require("common/syslog").Syslog)({ tag: "user_activation", pid: true })
shell     = new (require("common/shell").Shell)(syslog)

db        = require("common/database")

argv      = process.argv.slice(2)

shell.stdin 33, (error, code) ->
  if error
    syslog.send "err", "ERROR: #{error.message}"
    process.exit 1
  code = code.substring(0, 32)
  db.createDatabase syslog, (database) ->
    database.select "getActivationByCode", [ code ], "activation", (results) ->
      if results.length is 0
        syslog.send "err", "ERROR: Cannot find activation code #{code}."
        process.exit 1
      process.stdout.write("#{JSON.stringify(results.shift())}\n")
