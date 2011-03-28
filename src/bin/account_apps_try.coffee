# Open the system and get the account for the sudoer.
require("common/private").createSystem __filename, "account", (system, account) ->
  # Build a list of applications by reading all the local users assigned to
  # the account. The local users will have the applications attached. Each
  # application has at least one local user. This builds the full list of
  # applications.
  applications = { map: {}, array: [] }
  system.sql "getLocalUsersByAccount", [ account.id ], "localUser", (localUsers) ->
    for localUser in localUsers
      if not applications.map[localUser.application.id]
        applications.map[localUser.application.id] = localUser.application
        applications.array.push localUser.application
      application = applications.map[localUser.application.id]
      delete localUser.application.account
      delete localUser.application
      application.localUsers or= []
      application.localUsers.push(localUser)
    # Get all of the data stores associated with the account and assign them
    # to their applications.
    system.sql "getDataStoresByAccount", [ account.id ], "dataStore", (dataStores) ->
      for dataStore in dataStores
        application = applications.map[dataStore.application.id]
        delete dataStore.application.account
        delete dataStore.application
        delete dataStore.password
        application.dataStores or= []
        application.dataStores.push(dataStore)
      # For those applications with no data stores, create an empty list.
      for application in applications
        applications.dataStores or= []
      # Write the array of applications.
      process.stdout.write JSON.stringify(applications.array, null, 2)
      process.stdout.write "\n"
