require("common/private").createSystem __filename, (system) ->
  [ dataStoreId ] = process.argv.slice 2
  system.sql "getDataStore", [ dataStoreId ], "dataStore", (results) ->
    if results.length is 0
      process.exit 1
    dataStore = results.shift()
    process.stdout.write "#{dataStore.dataServer.hostname} #{dataStore.dataServer.port} #{dataStore.password}\n"
