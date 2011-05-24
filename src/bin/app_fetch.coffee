require("exclusive").createSystem __filename, "hostname, account", (system, hostname, account) ->
  # Choose a machine based on a weighted random where the weights are the
  # determined by the number of available machine users with policies.
  chooseMachine = (system, callback) ->
    system.sql "getMachines", [], "machine", (machines) ->
      machines = machines.filter (machine) -> machine.localUsers >
      machine.localUsersInUse
      for machine in machines
        machine.weight = 1 - (machine.localUsersInUse / machine.localUsers)
      sum = machines.reduce(((sum, machine) -> sum + machine.weight), 0)
      point = Math.random() * sum
      for machine in machines
        if machine.weight >= point
          callback(machine)
          return
        point -= machine.weight
      callback(null)

  localUserUnavailable = ->
    syslog.error "Unable to allocate local user account for application."
    process.stdout.write JSON.stringify({
      error: true
      message: "No new application accounts available at this time."
    })
    process.exit 0

  fetchLocalUser = (system, applicationId, machine) ->
    localUserUnavailable() unless machine
    system.sql "fetchLocalUser", [ applicationId, machine.id, 1 ], (results) =>
      if results.rowCount
        system.sql "getLocalUserByAssignment", [ results[0].id ], "localUser", (results) ->
          localUser = results.shift()
          system.enqueue localUser.machine.hostname, [
            [ "user:create", [ localUser.id ] ]
            [ "user:restorecon", [ localUser.id ] ]
            [ "user:decommission", [ localUser.id ] ]
            [ "user:provision", [ localUser.id ] ]
            [ "user:restorecon", [ localUser.id ] ]
            [ "user:skel", [ localUser.id, "protected" ] ]
            [ "user:authorize", [ localUser.id ] ]
            [ "user:config", [ localUser.id ] ]
            [ "user:restorecon", [ localUser.id ] ]
            [ "user:group", [ localUser.id, "protected" ] ]
            [ "user:chown", [ localUser.id ] ]
            [ "service:generate", [ localUser.id ] ]
            [ "init:restorecon", [ localUser.id ] ]
            [ "user:ready", [ localUser.id ] ]
          ], ->
            system.sql "getLocalPorts", [ localUser.machine.hostname, localUser.id ], "localPort", (localPorts) ->
              localPort = localPorts.shift()
              system.properties (properties) ->
                system.virtualHost "t#{applicationId}.#{properties.applicationHost}", localUser.machine.ip,  localPort.port, ->
                  system.sql "getApplications", [ account.id ], "application", (results) ->
                    applications = []
                    for application in results
                      if application.id is applicationId
                        application.status = "new"
                        applications.unshift application
                      else
                        application.status = if application.ready is 1 then "ready" else "pending"
                        applications.push application
                    process.stdout.write JSON.stringify({
                      error: false
                      applications
                    })
      else
        chooseMachine system, (machine) ->
          fetchLocalUser(system, applicationId, machine)

  # Select the machine at random, but there is only one machine for now.
  # Check that there are localUsers available on the machine.
  chooseMachine system, (machine) ->
    localUserUnavailable() unless machine
    system.sql "insertApplication", [ account.id, 0 ], (results) ->
      applicationId = results[0].id
      fetchLocalUser(system, applicationId, machine)
