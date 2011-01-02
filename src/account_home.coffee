require.paths.unshift("/puppy/lib/node")

database  = new (require("common/database").Database)()

sendEmailOrElse = (results, orElse) ->
  if results.length
    localUser = results.shift()
    process.stdout.write "u#{localUser.id + 10000}@#{localUser.machine.hostname}\n"
  else
    orElse()

argv = process.argv.slice(2)
[ email ] =  argv
database.select "getLocalUserByEmail", [ email ], "localUser", (results) ->
  sendEmailOrElse results, ->
    database.select "getLocalUserByActivationEmail", [ email ], "localUser", (results) ->
      sendEmailOrElse results, ->
        process.exit 1
