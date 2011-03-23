require.paths.unshift("/puppy/common/lib/node")

require("common").createSystem __filename, (system) ->
  [ email ] = process.argv.slice 2
  system.sql "getActivationByEmail", [ email ], "activation", (results) ->
    if results.length is 0
      throw new Error shell.err "ERROR: Cannot find activation for email #{email}."
    process.stdout.write "#{JSON.stringify(results.shift())}\n"
