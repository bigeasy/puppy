crypto    = require "crypto"
shell     = new (require("common/shell").Shell)()
database  = new (require("common/database").Database)()
#public    = require "./public"
exec      = require("child_process").exec

module.exports.command = (argv) ->
  register = (email, sshKey) ->
    hash = crypto.createHash "md5"
    hash.update(email +  sshKey + (new Date().toString()) + process.pid)
    code = hash.digest "hex"
    database.error = (error) ->
      if error.number is 1062
        if /'PRIMARY'/.test(error.message)
          register(email, sshKey)
        else if /'Activation_Email'/.test(error.message)
          process.stdout.write """
          The email address #{email} is already registered.\n
          """
      else
        throw error
    database.select "insertActivation", [ code, email, sshKey ], (results) ->
      database.select "getActivationByEmail", [ email ], "activation", (results) ->
        activation = results.shift()
        #public.sendActivation(activation)
        fetchActivationLocalUser activation.code

  fetchActivationLocalUser = (code) ->
    database.fetchLocalUser 1, (localUser) =>
      database.error = (error) =>
        throw error if error.number isnt 1062
        @fetchActivationLocalUser code
      database.select "fetchActivationLocalUser", [ code ], (results) =>
        if results.affectedRows is 0
          @fetchActivationLocalUser(code)
        else
          database.select "getLocalUserByActivationCode", [ code ], "localUser", (results) =>
            localUser = results.shift()
            shell.enqueue localUser.machine.hostname,
              [ "user:create", [ localUser.id ] ],
              [ "user:invite", [], code ]

  register argv[0], argv[1]
