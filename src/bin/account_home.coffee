# Prepend the Puppy node libraries to the library path.
require.paths.unshift("/puppy/common/lib/node")

# Get the program arguments.
[ email ] = process.argv.slice(2)

# Check the results of a query. If empty, fire a callback to try again. If
# non-empty, write the user name and host machine to stdout.
sendEmailOrElse = (results, orElse) ->
  if results.length
    localUser = results.shift()
    if localUser.application.account.ready
      process.stdout.write "u#{localUser.id}@#{localUser.machine.hostname}\n"
    else
      process.stdout.write "pending\n"
  else
    orElse()

# Search for the account first in the registered users, then in the users
# awaiting activation.
require("common/private").createSystem __filename, (system) ->
  system.sql "getLocalUserByEmail", [ email ], "localUser", (results) ->
    sendEmailOrElse results, ->
      system.sql "getLocalUserByActivationEmail", [ email ], "localUser", (results) ->
        sendEmailOrElse results, ->
          process.exit 1
