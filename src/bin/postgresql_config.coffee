require("exclusive").createSystem __filename, (system) ->
  [ hostname, uid ] = process.argv.slice 2
  system.sql "getDataStoresByLocalUser", [ hostname, uid ], "dataStore", (results) ->
    databases = {}
    for dataStore in results
      if dataStore.dataServer.engine is "PostgreSQL"
        process.stdout.write "*:*:d#{dataStore.id}:d#{dataStore.id}:#{dataStore.password}\n"
