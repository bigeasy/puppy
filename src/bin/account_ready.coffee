require("common/private").createSystem __fileame, (system) ->
  [ accountId ] = process.argv.slice 1
  system.sql "setAccountReady", [ accountId ], (results) ->
    system.verify(results.affectedRows is 1, "Unable to mark account #{accountId} ready.")
