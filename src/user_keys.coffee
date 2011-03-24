require.paths.unshift("/puppy/common/lib/node")

require("common/private").createSystem __filename, (system) ->
  [ hostname, uid ] = process.argv.slice 2
  system.sql "getAccountByLocalUser", [ hostname, uid ], "account", (results) ->
    if results.length is 0
      throw new Error system.err "Cannot find account on #{hostname} for user u#{uid}."
    account = results.shift()
    system.sql "getActivationByLocalUser", [ hostname, uid ], "activation", (results) ->
      process.stdout.write("#{account.sshKey}\n")
      if results.length
        activation = results.shift()
        process.stdout.write("command=\"/puppy/liminal/bin/liminal_receptionist\",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty #{activation.sshKey}\n")
