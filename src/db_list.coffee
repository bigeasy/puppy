require.paths.unshift("/puppy/lib/node")

syslog    = new (require("common/syslog").Syslog)({ tag: "db_list", pid: true })
shell     = new (require("common/shell").Shell)(syslog)
db        = require("common/database")

[ applicationId ] = process.argv.slice 2

db.createDatabase syslog, (database) ->
  database.uncaughtException()
  if applicationId
    database.application applicationId, (application) ->
      database.select "getDataStoresByApplication", [ application.id ], "dataStore", (dataStores) ->
        for ds in dataStores
          ds.status = "ready"
          delete ds.password
        process.stdout.write JSON.stringify({
          error: false
          dataStores
        })
  else
    database.account (account) ->
      database.select "getDataStoresByAccount", [ account.id ], "dataStore", (dataStores) ->
        for ds in dataStores
          ds.status = "ready"
          delete ds.password
        process.stdout.write JSON.stringify({
          error: false
          dataStores
        })
