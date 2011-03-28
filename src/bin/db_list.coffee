# Connect to the database.
require("common/private").createSystem __filename, (system) ->
  [ applicationId ] = process.argv.slice 2
  # If we're given an application id, list the databases for the application,
  # otherwise, list all databases. Delete the database passwords from the
  # results returned to the client.
  if applicationId
    # The `application` method will verify that the machine user is associated
    # with the application id.
    system.application applicationId, (application) ->
      system.sql "getDataStoresByApplication", [ application.id ], "dataStore", (dataStores) ->
        for ds in dataStores
          ds.status = "ready"
          delete ds.password
        process.stdout.write JSON.stringify({
          error: false
          dataStores
        }, null, 2)
  else
    system.account (account) ->
      system.sql "getDataStoresByAccount", [ account.id ], "dataStore", (dataStores) ->
        for ds in dataStores
          ds.status = "ready"
          delete ds.password
        process.stdout.write JSON.stringify({
          error: false
          dataStores
        }, null, 2)
