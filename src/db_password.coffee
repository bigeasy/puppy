require.paths.unshift("/puppy/common/lib/node")

syslog          = new (require("common/syslog").Syslog)({ tag: "db_fetch", pid: true })
shell           = new (require("common/shell").Shell)(syslog)
db              = require("common/database")

argv            = process.argv.slice 2

dataStoreId     = parseInt argv.shift(), 10

db.createDatabase syslog, (database) ->
  database.select "getDataStore", [ dataStoreId ], "dataStore", (results) ->
    if results.length is 0
      process.exit 1
    dataStore = results.shift()
    process.stdout.write "#{dataStore.dataServer.hostname} #{dataStore.dataServer.port} #{dataStore.password}\n"
