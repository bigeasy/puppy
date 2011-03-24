# Prepend the puppy library directory to the path.
require.paths.unshift("/puppy/common/lib/node")

require("common/private").createSystem __filename, (system) ->
  # Read command line arguments, hostname and port.
  [ hostname ] = process.argv.slice(2)

  system.sql "getLocalPortsByHostname", [ hostname ], "localPort", (localPorts) ->
    for localPort in localPorts
      process.stdout.write "#{localPort.localUser.id} #{localPort.port}\n"