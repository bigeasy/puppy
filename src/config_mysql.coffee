require.paths.unshift("/puppy/common/lib/node")

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
    database.select "getDataStoresByLocalUser", [ hostname, uid ], "dataStore", (results) ->
      databases = {}
      for dataStore in results
        if dataStore.dataServer.engine is "mysql"
          process.stdout.write "#{dataStore.alias} #{dataStore.password}\n"
