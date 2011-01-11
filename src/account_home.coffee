# Prepend the Puppy node libraries to the library path.
require.paths.unshift("/puppy/lib/node")

# Create syslog and import the database library.
syslog    = new (require("common/syslog").Syslog)({ tag: "account_register", pid: true })
db        = require("common/database")


# Get the program arguments.
argv      = process.argv.slice(2)
email     =  argv.shift()

# Check the results of a query. If empty, fire a callback to try again. If
# non-empty, write the user name and host machine to stdout.
sendEmailOrElse = (results, orElse) ->
  if results.length
    localUser = results.shift()
    process.stdout.write "u#{localUser.id}@#{localUser.machine.hostname}\n"
  else
    orElse()

# Search for the account first in the registered users, then in the users
# awaiting activation.
db.createDatabase syslog, (database) ->
  database.select "getLocalUserByEmail", [ email ], "localUser", (results) ->
    sendEmailOrElse results, ->
      database.select "getLocalUserByActivationEmail", [ email ], "localUser", (results) ->
        sendEmailOrElse results, ->
          process.exit 1
