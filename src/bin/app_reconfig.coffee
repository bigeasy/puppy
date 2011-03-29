require("exclusive").createSystem __filename, (system) ->
  [ appId ] = process.argv.slice 2
  system.sql "getApplicationLocalUsers", [ appId ], "localUser", (results) ->
    for localUser in results
      system.enqueue localUser.machine.hostname, [
        [ "user:config", [ localUser.id ] ],
        [ "user:restorecon", [ localUser.id ] ],
        [ "user:group", [ localUser.id, "protected" ] ],
        [ "user:chown", [ localUser.id ] ]
      ]
