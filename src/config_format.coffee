require.paths.unshift("/puppy/lib/node")

exec      = require("child_process").exec
syslog    = new (require("common/syslog").Syslog)({ tag: "configuration_read", pid: true })
shell     = new (require("common/shell").Shell)(syslog)
prettify  = require("common/pretty").prettify
db        = require("common/database")

argv      = process.argv.slice 2
uid       = parseInt argv.shift(), 10
address   = argv.shift()

db.createDatabase syslog, (database) ->
  shell.hostname (hostname) ->
    database.select "getLocalPorts", [ hostname, uid ], "localPort", (results) ->
      ports = results.map (localPort) -> localPort.port
      process.stdout.write prettify { address
                                    , app: "/home/u#{uid}/app"
                                    , ports
                                    , "var": "/home/u#{uid}/var"
                                    , "tmp": "/home/u#{uid}/tmp"
                                    }
