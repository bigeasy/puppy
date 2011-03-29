# Connect to the database.
require("exclusive").createSystem __filename, "applicationId or 0", (system, applicationId) ->
  # If we're given an application id, list the databases for the application,
  # otherwise, list all databases. Delete the database passwords from the
  # results returned to the client.
  if applicationId is 0
    system.account (account) ->
      system.sql "getDataStoresByAccount", [ account.id ], "dataStore", (dataStores) ->
        for ds in dataStores
          # FIXME Implement ready for real.
          ds.status = "ready"
          delete ds.password
        process.stdout.write JSON.stringify({
          error: false
          dataStores
        }, null, 2)
  else
    # The `application` method will verify that the machine user is associated
    # with the application id.
    system.application (application) ->
      system.sql "getDataStoresByApplication", [ application.id ], "dataStore", (dataStores) ->
        for ds in dataStores
          ds.status = "ready"
          delete ds.password
        process.stdout.write JSON.stringify({
          error: false
          dataStores
        }, null, 2)
