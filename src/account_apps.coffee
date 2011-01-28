require.paths.unshift("/puppy/lib/node")

sys       = require "sys"
exec      = require("child_process").exec
syslog    = new (require("common/syslog").Syslog)({ tag: "configuration_read", pid: true })
shell     = new (require("common/shell").Shell)(syslog)
prettify  = require("common/pretty").prettify
db        = require("common/database")

uid = parseInt process.env["SUDO_UID"], 10
shell.verify(uid > 10000, "Inexplicable uid #{uid}")

getApplicationLocalUsers = (database, applications) ->
getApplicationDataStores = (database, account) ->

db.createDatabase syslog, (database) ->
  shell.hostname (hostname) ->
    database.select "getAccountByLocalUser", [ hostname, uid ], "account", (accounts) ->
      account = accounts.shift()
      applications = { map: {}, array: [] }
      database.select "getLocalUsersByAccount", [ account.id ], "localUser", (localUsers) ->
        for localUser in localUsers
          if not applications.map[localUser.application.id]
            applications.map[localUser.application.id] = localUser.application
            applications.array.push localUser.application
          application = applications.map[localUser.application.id]
          application.localUsers or= []
          delete localUser.application.account
          delete localUser.application
          application.localUsers.push(localUser)
        database.select "getDataStoresByAccount", [ account.id ], "dataStore", (dataStores) ->
          for dataStore in dataStores
            application = applications.map[dataStore.application.id]
            application.dataStores or= []
            delete dataStore.application.account
            delete dataStore.application
            delete dataStore.password
            application.dataStores.push(dataStore)
          process.stdout.write JSON.stringify(applications.array)
