require.paths.unshift("/puppy/common/lib/node")

# Select the machine local users for the local host.
require("common/private").createSystem __filename, (system) ->
  [ hostname ] = process.argv.slice(2)
  system.sql "getMachineLocalUsers", [ hostname, 1 ], "localUser", (results) ->
    for localUser in results
      process.stdout.write "#{localUser.id}\n"