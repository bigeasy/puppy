# Prepend the puppy library directory to the path.
require.paths.unshift("/puppy/common/lib/node")

# Import Puppy libraries.
syslog    = new (require("common/syslog").Syslog)({ tag: "port_list", pid: true })
shell     = new (require("common/shell").Shell)(syslog)
db        = require("common/database")

# Read command line arguments, hostname and port.
argv      = process.argv.slice(2)
hostname  = argv.shift()

db.createDatabase syslog, (database) ->
  database.select "getLocalPortsByHostname", [ hostname ], "localPort", (localPorts) ->
    for localPort in localPorts
      process.stdout.write "#{localPort.localUser.id} #{localPort.port}\n"
