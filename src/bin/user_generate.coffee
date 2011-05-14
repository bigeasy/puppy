require("exclusive").createSystem __filename, (system) ->
  [ policies ] = process.argv.slice 2
  system.database (error, database) ->
    generate = (hostname, machine, localUsers) ->
      createLocalPort = (localUserId, service) ->
        database.sql "nextLocalPort", [ machine.id ], (error, results) ->
          throw error if error
          nextLocalPort = results[0].nextLocalPort
          database.sql "insertLocalPort", [ machine.id, nextLocalPort ], (error, results) ->
            throw error if error
            fetchLocalPort localUserId, service

      fetchLocalPort = (localUserId, service) ->
        database.sql "fetchLocalPort", [ localUserId, service, machine.id ], (error, results) ->
          throw error if error
          if results.rowCount is 0
            createLocalPort localUserId, service
          else
            createLocalPorts(localUserId)

      createLocalPorts = (localUserId) ->
        system.sql "getLocalPorts", [ hostname, localUserId ], "localPort", (results) ->
          if results.length < 7
            fetchLocalPort localUserId, 1
          else
            nextLocalUser()

      createLocalUsers = () ->
        database.sql "getLocalUserCount", [ machine.id, 10001, 20000 ], (error, results) ->
          throw error if error
          if results[0].localUserCount < policies
            database.sql "nextLocalUser", [ machine.id, 20000 ], (error, results) ->
              throw error if error
              nextLocalUserId = results[0].nextLocalUserId
              database.sql "insertLocalUser", [ machine.id, nextLocalUserId, true, false ], (error, results) ->
                throw error if error
                createLocalPorts(nextLocalUserId)
          else
            process.stdout.write "Done.\n"
            database.close()
      nextLocalUser = () ->
        if localUsers.length
          localUser = localUsers.shift()
          createLocalPorts(localUser.id)
        else
          createLocalUsers()
      nextLocalUser()

    system.hostname (hostname) ->
      database.sql "getMachineByHostname", [ hostname ], "machine", (error, results) ->
        throw error if error
        machine = results.shift()
        database.sql "getLocalUsers", [ machine.id, 10001, 20000 ], "localUser", (error, localUsers) ->
          throw error if error
          generate(hostname, machine, localUsers)
