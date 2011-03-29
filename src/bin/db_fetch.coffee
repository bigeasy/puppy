fs              = require "fs"
crypto          = require "crypto"

fetchDataStore = (system, applicationId, engine, alias, application) ->
  hash = crypto.createHash "md5"
  urandom = fs.createReadStream "/dev/urandom", { start: 0, end: 4091 }
  urandom.on "data", (chunk) -> hash.update chunk
  urandom.on "end", ->
    system.sql "insertDataStore", [ applicationId, alias, hash.digest("hex"), engine ], (results) ->
      system.sql "getDataStore", [ results.insertId ], "dataStore", (dataStores) ->
        dataStore = dataStores.shift()
        system.enqueue dataStore.dataServer.hostname, [
          [ "mysql:create", [ dataStore.id ] ],
          [ "mysql:grant", [ applicationId, dataStore.id ] ]
          [ "app:reconfig", [ applicationId ] ]
        ], ->
          system.sql "getDataStoresByApplication", [ applicationId ], "dataStore", (results) ->
            dataStores = []
            for ds in results
              if ds.id is dataStore.id
                ds.status = "new"
                dataStores.unshift ds
              else
                ds.status = "ready"
                dataStores.push ds
            process.stdout.write JSON.stringify({
              error: false
              dataStores
            }, null, 2)
require("exclusive").createSystem __filename, "applicationId, engine, alias, application", fetchDataStore
