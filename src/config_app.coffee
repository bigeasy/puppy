require.paths.unshift("/puppy/common/lib/node")

exec      = require("child_process").exec
syslog    = new (require("common/syslog").Syslog)({ tag: "config_app", pid: true })
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
      database.select "getDataStoresByLocalUser", [ hostname, uid ], "dataStore", (results) ->
        databases = {}
        for dataStore in results
          databases[dataStore.alias] =
            name: "d#{dataStore.id}"
            alias: dataStore.alias
            engine: dataStore.dataServer.engine
            password: dataStore.password
            hostname: dataStore.dataServer.hostname
            port: dataStore.dataServer.port
        process.stdout.write prettify { address
                                      , app: "/home/u#{uid}/app"
                                      , ports
                                      , "var": "/home/u#{uid}/var"
                                      , "tmp": "/home/u#{uid}/tmp"
                                      , databases
                                      }
