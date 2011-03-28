require("common/private").createSystem __filename, (system) ->
  [ hostname, uid ] = process.argv.slice 2
  system.sql "getDataStoresByLocalUser", [ hostname, uid ], "dataStore", (results) ->
    databases = {}
    for dataStore in results
      if dataStore.dataServer.engine is "mysql"
        process.stdout.write "#{dataStore.alias} #{dataStore.password}\n"
