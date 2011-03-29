require("exclusive").createSystem __filename, "hostname, uid", (system, hostname, uid) ->
  system.sql "getApplicationByLocalUser", [ hostname, uid ], "application", (applications) ->
    application = applications.shift()
    system.sql "getApplicationLocalUsers", [ application.id ], "localUser", (localUsers) ->
      for localUser in localUsers
        if localUser.machine.hostname is hostname and localUser.id is uid
          system.enqueue localUser.machine.hostname, [
              [ "daemon:stop", [ localUser.id ] ]
              [ "app:deploy", [ localUser.id ] ]
              [ "daemon:start", [ localUser.id ] ]
          ]
