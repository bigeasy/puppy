setDbAlias = (system, applicationId, dataStoreId, alias, hostname, application) ->
  # Detailed checking is performed on the client side, here we check to see that
  # no one is directly injecting junk.
  if not alias? or /^d\d+/.test(alias) or not /^[-\d\w_$]+$/.test(alias)
    throw new Error system.err "Invalid alias.", { argv: [ dataStoreId, alias ] }
  
  system.error = (error) =>
    throw error if error.number isnt 1062
    process.stdout.write JSON.stringify({ constraintViolation: true }, null, 2)
    process.stdout.write "\n"
  # The query will only select a data store that is assigned to the current
  # application.
  system.sql "setDataStoreAlias", [ alias, dataStoreId, application.id ], (results) ->
    if results.affectedRows is 0
      process.stdout.write JSON.stringify({ notFound: true })
      process.stdout.write "\n"
    else
      system.sql "getDataStore", [ dataStoreId ], "dataStore", (dataStores) ->
        dataStore = dataStores.shift()
        system.enqueue hostname, [
          [ "app:reconfig", [ dataStore.applicationId ] ]
        ], ->
          dataStore.status = "ready"
          delete dataStore.password
          process.stdout.write JSON.stringify({ dataStore }, null, 2)
          process.stdout.write "\n"
require("exclusive").createSystem __filename, "applicationId or 0, dataStoreId or 0, alias, hostname, application", setDbAlias
