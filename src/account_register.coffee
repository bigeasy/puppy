crypto    = require "crypto"
shell     = new (require("puppy/shell").Shell)()
database  = new (require("puppy/database").Database)()

module.exports.command = (bin, argv) ->
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
      fetchActivationLocalUser code

  fetchActivationLocalUser = (code) ->
    database.fetchLocalUser 1, (localUser) =>
      database.error = (error) =>
        throw error if error.number isnt 1062
        @fetchActivationLocalUser code
      database.select "fetchActivationLocalUser", [ code ], (results) =>
        if results.affectedRows is 0
          @fetchActivationLocalUser(code)
        else
          database.select "getLocalUserByActivation", [ code ], "localUser", (results) =>
            console.log results
            console.log "MUST CREATE LOCAL USER"

  register argv[0], argv[1]
