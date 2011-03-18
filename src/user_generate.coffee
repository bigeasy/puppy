require.paths.unshift("/puppy/common/lib/node")

require("common").createSystem __filename, (system) ->
  [ policies ] = process.argv.slice 2

  generate = (system, hostname, machine, localUsers) ->
    createLocalPorts = (localUserId) ->
      system.sql "getLocalPorts", [ hostname, localUserId ], "localPort", (results) ->
        if results.length < 7
          system.fetchLocalPort machine.id, localUserId, 1, (localPort) ->
            createLocalPorts(localUserId)
        else
          nextLocalUser()
    createLocalUsers = () ->
      system.sql "getLocalUserCount", [ machine.id, 10001, 20000 ], (results) ->
        if results[0].localUserCount < policies
          system.sql "nextLocalUser", [ machine.id, 20000 ], (results) =>
            nextLocalUserId = results[0].nextLocalUserId
            system.error = (error) =>
              throw error if error.number isnt 1062
              system.createLocalUser machineId, count, callback
            system.sql "insertLocalUser", [ machine.id, nextLocalUserId, 1, 0 ], (results) =>
              createLocalPorts(nextLocalUserId)
        else
          process.stdout.write "Done.\n"
    nextLocalUser = () ->
      if localUsers.length
        localUser = localUsers.shift()
        createLocalPorts(localUser.id)
      else
        createLocalUsers()
    nextLocalUser()

  system.hostname (hostname) ->
    system.sql "getMachineByHostname", [ hostname ], "machine", (results) ->
      machine = results.shift()
      system.sql "getLocalUsers", [ machine.id, 10001, 20000 ], "localUser", (localUsers) ->
        generate(system, hostname, machine, localUsers)
