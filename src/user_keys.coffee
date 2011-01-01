require.paths.unshift("/puppy/lib/node")

syslog    = new (require("common/syslog").Syslog)({ tag: "user_keys", pid: true })
shell     = new (require("common/shell").Shell)(syslog)

db        = require("common/database")

# Get the program arguments.
argv      = process.argv.slice(2)
hostname  = argv.shift()
id        = parseInt argv.shift(), 10

db.createDatabase syslog, (database) ->
  database.select "getAccountByLocalUser", [ hostname, id ], "account", (results) ->
    if results.length is 0
      syslog.send "err", "ERROR: Cannot find account on #{hostname} for user u#{10000 + id}."
      process.exit 1
    account = results.shift()
    database.select "getActivationByLocalUser", [ hostname, id ], "activation", (results) ->
      process.stdout.write("#{account.sshKey}\n")
      if results.length
        activation = results.shift()
        process.stdout.write("#{activation.sshKey}\n")
