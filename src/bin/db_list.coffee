# Prepend the Puppy node libraries to the library path.
require.paths.unshift("/puppy/common/lib/node")

# Create syslog and import the database library.
syslog    = new (require("common/syslog").Syslog)({ tag: "db_list", pid: true })
db        = require("common/database")

# Get the program arguments.
[ applicationId ] = process.argv.slice 2

# Connect to the database.
db.createDatabase syslog, (database) ->
  database.uncaughtException()
  # If we're given an application id, list the databases for the application,
  # otherwise, list all databases. Delete the database passwords from the
  # results returned to the client.
  if applicationId
    # The `application` method will verify that the machine user is associated
    # with the application id.
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
