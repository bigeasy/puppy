require("common/private").createSystem __filename, (system) ->
  [ appId ] = process.argv.slice 2
  system.sql "getApplicationLocalUsers", [ appId ], "localUser", (results) ->
    for localUser in results
      process.stdout.write "#{localUser.machine.hostname} #{localUser.id}\n"
