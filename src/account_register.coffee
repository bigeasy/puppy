require.paths.unshift("/puppy/common/lib/node")

crypto    = require "crypto"

require("common").createSystem __filename, (system) ->
  [ email, sshKey ] = process.argv.slice 2
  register = () ->
    hash = crypto.createHash "md5"
    hash.update(email +  sshKey + (new Date().toString()) + process.pid)
    code = hash.digest "hex"
    system.error = (error) ->
      if error.number is 1062
        if /'PRIMARY'/.test(error.message)
          register(email, sshKey)
        else if /'Activation_Email'/.test(error.message)
          process.stdout.write """
          The email address #{email} is already registered.\n
          """
      else
        throw error
    system.sql "insertActivation", [ code, email, sshKey ], (results) ->
      system.sql "getActivationByEmail", [ email ], "activation", (results) ->
        activation = results.shift()
        #public.sendActivation(activation)
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
              [ "node:ready", [ localUser.id ] ],
              [ "user:invite", [ email ] ]
            ]
  register()
