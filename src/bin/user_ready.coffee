require("common/private").createSystem __filename, (system) ->
  [ hostname, uid ] = process.argv.slice 2
  system.sql "setApplicationLocalUserReady", [ hostname, uid ], (results) ->
    system.verify(results.affectedRows is 1, "Unable to mark local user u#{uid} on #{hostname} ready.")
