database  = new (require("common/database").Database)()

sendEmailOrElse = (results, orElse) ->
  if results.length
    localUser = results.shift()
    process.stdout.write "u#{localUser.id + 10000}@#{localUser.machine.hostname}\n"
  else
    orElse()

module.exports.command = (bin, argv) ->
  [ email ] =  argv
  database.select "getLocalUserByEmail", [ email ], "localUser", (results) ->
    sendEmailOrElse results, ->
      database.select "getLocalUserByActivationEmail", [ email ], "localUser", (results) ->
        sendEmailOrElse results, ->
          process.exit 1
