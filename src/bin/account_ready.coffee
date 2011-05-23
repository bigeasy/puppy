require("exclusive").createSystem __filename, (system) ->
  [ accountId ] = process.argv.slice 2
  system.sql "setAccountReady", [ accountId ], (results) ->
    system.verify(results.rowCount is 1, "Unable to mark account #{accountId} ready.")
