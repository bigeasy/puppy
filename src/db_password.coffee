require.paths.unshift("/puppy/lib/node")

syslog          = new (require("common/syslog").Syslog)({ tag: "db_fetch", pid: true })
shell           = new (require("common/shell").Shell)(syslog)
db              = require("common/database")

argv            = process.argv.slice 2

hostname        = argv.shift()
uid             = argv.shift()
dataStoreId     = parseInt argv.shift(), 10

db.createDatabase syslog, (database) ->
  database.select "getDataStoresByLocalUser", [ hostname, uid ], "dataStore", (results) ->
    found = null
    for dataStore in results
      if dataStore.id is dataStoreId
        found = dataStore
        break
    if not found
      process.exit 1
    process.stdout.write "#{found.dataServer.hostname} #{found.dataServer.port} #{found.password}\n"
