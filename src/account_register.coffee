require.paths.unshift("/puppy/lib/node")

syslog    = new (require("common/syslog").Syslog)({ tag: "account_register", pid: true })
shell     = new (require("common/shell").Shell)(syslog)

db        = require("common/database")

#public    = require "./public"

argv      = process.argv.slice(2)

exec      = require("child_process").exec
crypto    = require "crypto"

db.createDatabase syslog, (database) ->
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
    database.fetchLocalUser 1, (localUser) ->
      database.error = (error) ->
        throw error if error.number isnt 1062
        fetchActivationLocalUser code
      database.select "fetchActivationLocalUser", [ code ], (results) ->
        if results.affectedRows is 0
          fetchActivationLocalUser(code)
        else
          database.select "getLocalUserByActivationCode", [ code ], "localUser", (results) =>
            localUser = results.shift()
            shell.enqueue localUser.machine.hostname,
              [ "user:create", [ localUser.id ] ],
              [ "user:restorecon", [ localUser.id ] ],
              [ "user:provision", [ localUser.id ] ],
              [ "user:restorecon", [ localUser.id ] ],
              [ "user:authorize", [ localUser.id ] ],
              [ "user:restorecon", [ localUser.id ] ],
              [ "user:group", [ localUser.id, "unregistered" ] ],
              [ "user:chown", [ localUser.id ] ],
              [ "user:invite", [], code ]

  register argv[0], argv[1]