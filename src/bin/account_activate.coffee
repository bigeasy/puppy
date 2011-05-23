require("exclusive").createSystem __filename, "hostname", (system, hostname) ->
  authorize = (hostname, code) ->
    system.sql "getLocalUserByActivationCode", [ code ], "localUser", (results) ->
      system.verify(results.length is 1, "Cannot find activation for code #{code}.")
      localUser = results.shift()
      system.verify(localUser.machine.hostname is hostname, "Incorrect hostname #{hostname}.")
      system.verify(localUser.id is parseInt(process.env["SUDO_UID"], 10),
        "SUDO_UID #{process.env["SUDO_UID"]} does not match #{localUser.id}.")
      activate(localUser, code)

  activate = (localUser, code) ->
    system.sql "activate", [ code ], (results) ->
      if results.affectedRows != 0
        system.sql "dropActivationLocalUser", [ localUser.machineId, localUser.id ], (results) ->
          system.sql "dropApplicationLocalUser", [ localUser.machineId, localUser.id ], (results) ->
            account(code)

  account = (code) ->
    system.sql "getActivationByCode", [ code ], "activation", (results) ->
      activation = results.shift()
      system.sql "insertAccount", [ activation.email, activation.sshKey ], (results) ->
        accountId = results[0].id
        system.sql "insertApplication", [ accountId, true ], (results) ->
          system.fetchLocalUser results[0].id, (localUser) ->
            system.enqueue localUser.machine.hostname, [
              [ "user:create", [ localUser.id ] ]
              [ "user:restorecon", [ localUser.id ] ]
              [ "user:decommission", [ localUser.id ] ]
              [ "user:provision", [ localUser.id ] ]
              [ "user:restorecon", [ localUser.id ] ]
              [ "user:skel", [ localUser.id, "protected" ] ]
              [ "user:authorize", [ localUser.id ] ]
              [ "user:restorecon", [ localUser.id ] ]
              [ "user:group", [ localUser.id, "protected" ] ]
              [ "user:chown", [ localUser.id ] ]
              [ "user:ready", [ localUser.id ] ]
              [ "account:ready", [ accountId ] ]
            ]
            process.stdout.write "Activation successful. Welcome to Puppy.\n"

  system.shell.stdin 33, (error, stdin) ->
    throw error if error
    authorize(hostname, stdin.trim())
