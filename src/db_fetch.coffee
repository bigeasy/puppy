require.paths.unshift("/puppy/common/lib/node")

exec            = require("child_process").exec
fs              = require "fs"
crypto          = require "crypto"
syslog          = new (require("common/syslog").Syslog)({ tag: "db_fetch", pid: true })
shell           = new (require("common/shell").Shell)(syslog)
db              = require("common/database")
{OptionParser}  = require("coffee-script/optparse")

[ app, engine, alias ] = process.argv.slice 2

db.createDatabase syslog, (database) ->
  database.uncaughtException()
  database.application app, (application) ->
    hash = crypto.createHash "md5"
    urandom = fs.createReadStream "/dev/urandom", { start: 0, end: 4091 }
    urandom.on "data", (chunk) -> hash.update chunk
    urandom.on "end", ->
      database.select "insertDataStore", [ app, alias, hash.digest("hex"), engine ], (results) ->
        database.select "getDataStore", [ results.insertId ], "dataStore", (dataStores) ->
          dataStore = dataStores.shift()
          database.enqueue dataStore.dataServer.hostname, [
            [ "mysql:create", [ dataStore.id ] ],
            [ "mysql:grant", [ app, dataStore.id ] ]
            [ "app:config", [ app ] ]
          ], ->
            database.select "getDataStoresByApplication", [ app ], "dataStore", (results) ->
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
              })
