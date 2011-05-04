crypto    = require "crypto"

require("exclusive").createSystem __filename, (system) ->
  [ email, sshKey ] = process.argv.slice 2
  register = () ->
    hash = crypto.createHash "md5"
    hash.update(email +  sshKey + (new Date().toString()) + process.pid)
    code = hash.digest "hex"

    # Create a connection that we can use to handle the error ourselves.
    system.database (error, database) ->
      throw error if error
      database.sql "insertActivation", [ code, email, sshKey ], (error, results) ->
        database.close()
        if error
          if error.number is 1062
            if /'PRIMARY'/.test(error.message)
              register(email, sshKey)
            else if /'Activation_Email'/.test(error.message)
              process.stdout.write """
              The email address #{email} is already registered.\n
              """
          else
            throw error
        else
          system.sql "getActivationByEmail", [ email ], "activation", (results) ->
            activation = results.shift()
            fetchActivationLocalUser activation.code

  fetchActivationLocalUser = (code) ->
    system.fetchLocalUser 1, (localUser) ->
      system.error = (error) ->
        throw error if error.number isnt 1062
        fetchActivationLocalUser code
      system.sql "fetchActivationLocalUser", [ code ], (results) ->
        if results.affectedRows is 0
          fetchActivationLocalUser(code)
        else
          system.sql "getLocalUserByActivationCode", [ code ], "localUser", (results) =>
            localUser = results.shift()
            system.enqueue localUser.machine.hostname, [
              [ "user:create", [ localUser.id ] ],
              [ "user:restorecon", [ localUser.id ] ],
              [ "user:decommission", [ localUser.id ] ],
              [ "user:provision", [ localUser.id ] ],
              [ "user:restorecon", [ localUser.id ] ],
              [ "user:skel", [ localUser.id, "liminal" ] ]
              [ "user:authorize", [ localUser.id ] ],
              [ "user:restorecon", [ localUser.id ] ],
              [ "user:group", [ localUser.id, "liminal" ] ],
              [ "user:chown", [ localUser.id ] ],
              [ "user:ready", [ localUser.id ] ],
              [ "user:invite", [ email ] ]
            ]
  register()
