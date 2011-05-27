fs              = require "fs"
crypto          = require "crypto"

fetchDataStore = (system, applicationId, engine, alias, application) ->
  hash = crypto.createHash "md5"
  urandom = fs.createReadStream "/dev/urandom", { start: 0, end: 4091 }
  urandom.on "data", (chunk) -> hash.update chunk
  urandom.on "end", ->
    system.sql "insertDataStore", [ applicationId, alias, hash.digest("hex"), engine ], (results) ->
      if results.rowCount is 0
        throw new Error system.err "Cannot create data store.", { engine, alias }
      system.sql "getDataStore", [ results[0].id ], "dataStore", (dataStores) ->
        dataStore = dataStores.shift()
        system.enqueue dataStore.dataServer.hostname, [
          [ "postgresql:create", [ dataStore.id ] ],
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
