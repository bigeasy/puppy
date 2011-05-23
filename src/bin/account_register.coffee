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
          if error.code is '23505'
            if /'PRIMARY'/.test(error.message)
              register(email, sshKey)
            else if /^Key \(email\)=/.test(error.detail)
              process.stdout.write """
              The email address #{email} is already registered.\n
              """
            else
              throw error
          else
            throw error
        else
          system.sql "getActivationByEmail", [ email ], "activation", (results) ->
            activation = results.shift()
            fetchActivationLocalUser activation.code

  fetchActivationLocalUser = (code) ->
    system.fetchLocalUser 1, (localUser) ->
      system.sql "fetchActivationLocalUser", [ code ], (results) ->
        if results.rowCount is 0
          fetchActivationLocalUser code
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
