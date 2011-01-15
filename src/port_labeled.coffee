# Prepend the puppy library directory to the path.
require.paths.unshift("/puppy/lib/node")

# Import Puppy libraries.
syslog    = new (require("common/syslog").Syslog)({ tag: "port_labeled", pid: true })
shell     = new (require("common/shell").Shell)(syslog)
db        = require("common/database")

# Read command line arguments, hostname and port.
argv      = process.argv.slice(2)
hostname  = argv.shift()
port      = parseInt argv.shift(), 10

db.createDatabase syslog, (database) ->
  if argv.length is 0
    database.select "getLocalPort", [ hostname, port ], "localPort", (results) ->
      if results.length is 0
        syslog.send "err", "ERROR: Cannot find port #{port} on #{hostname}."
        process.exit 1
      localPort = results.shift()
      process.stdout.write "#{localPort.labeled}\n"
  else
    labeled = argv.shift()
    database.select "setLocalPortLabeled", [ labeled, hostname, port ], (results) ->
      if results.affectedRows is 0
        syslog.send "err", "ERROR: Cannot find port #{port} on #{hostname}."
        process.exit 1
