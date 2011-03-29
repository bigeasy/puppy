require("exclusive").createSystem __filename, (system) ->
  # Read command line arguments, hostname and port.
  [ hostname ] = process.argv.slice(2)

  system.sql "getLocalPortsByHostname", [ hostname ], "localPort", (localPorts) ->
    for localPort in localPorts
      process.stdout.write "#{localPort.localUser.id} #{localPort.port}\n"
