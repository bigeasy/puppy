# Connect to the database.
require("exclusive").createSystem __filename, "hostname, account", (system, hostname, account) ->
  [ alias, dsId ] = process.argv.slice 2
  system.sql "setDataStoreAlias", [ alias, dsId, account.id ], (results) ->
    if results.affectedRows is 0
      process.stdout.write JSON.stringify({ error: "not-found" })
      process.stdout.write "\n"
    else
      system.sql "getDataStore", [ dsId ], "dataStore", (dataStores) ->
        dataStore = dataStores.shift()
        system.enqueue hostname, [
          [ "app:reconfig", [ dataStore.applicationId ] ]
        ], ->
          process.stdout.write JSON.stringify({})
          process.stdout.write "\n"
