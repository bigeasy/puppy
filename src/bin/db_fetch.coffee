fs              = require "fs"
crypto          = require "crypto"

require("common/private").createSystem __filename, (system) ->
  [ app, engine, alias ] = process.argv.slice 2
  system.application app, (application) ->
    hash = crypto.createHash "md5"
    urandom = fs.createReadStream "/dev/urandom", { start: 0, end: 4091 }
    urandom.on "data", (chunk) -> hash.update chunk
    urandom.on "end", ->
      system.sql "insertDataStore", [ app, alias, hash.digest("hex"), engine ], (results) ->
        system.sql "getDataStore", [ results.insertId ], "dataStore", (dataStores) ->
          dataStore = dataStores.shift()
          system.enqueue dataStore.dataServer.hostname, [
            [ "mysql:create", [ dataStore.id ] ],
            [ "mysql:grant", [ app, dataStore.id ] ]
            [ "app:reconfig", [ app ] ]
          ], ->
            system.sql "getDataStoresByApplication", [ app ], "dataStore", (results) ->
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
