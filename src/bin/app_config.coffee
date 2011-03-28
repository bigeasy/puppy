require("common/private").createSystem __filename, (system) ->
  [ hostname, uid, address ] = process.argv.slice 2
  system.sql "getLocalPorts", [ hostname, uid ], "localPort", (results) ->
    ports = results.map (localPort) -> localPort.port
    system.sql "getDataStoresByLocalUser", [ hostname, uid ], "dataStore", (results) ->
      databases = {}
      for dataStore in results
        databases[dataStore.alias] =
          name: "d#{dataStore.id}"
          alias: dataStore.alias
          engine: dataStore.dataServer.engine
          password: dataStore.password
          hostname: dataStore.dataServer.hostname
          port: dataStore.dataServer.port
      process.stdout.write JSON.stringify {
        address
        app: "/home/u#{uid}/app"
        ports
       "var": "/home/u#{uid}/var"
       "tmp": "/home/u#{uid}/tmp"
       databases
     }, null, 2
