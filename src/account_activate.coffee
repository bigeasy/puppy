require.paths.unshift("/puppy/lib/node")

exec      = require("child_process").exec
syslog    = new (require("common/syslog").Syslog)({ tag: "account_activate", pid: true })
shell     = new (require("common/shell").Shell)(syslog)
db        = require("common/database")

argv = process.argv.slice 2
hostname = argv.shift()

db.createDatabase syslog, (database) ->
  authorize = (hostname, code) ->
    database.select "getLocalUserByActivationCode", [ code ], "localUser", (results) ->
      shell.verify(results.length is 1, "Cannot find activation for code #{code}.")
      localUser = results.shift()
      shell.verify(localUser.machine.hostname is hostname, "Incorrect hostname #{hostname}.")
      shell.verify(localUser.id is parseInt(process.env["SUDO_UID"], 10),
        "SUDO_UID #{process.env["SUDO_UID"]} does not match #{localUser.id}.")
      activate(localUser, code)

  activate = (localUser, code) ->
    database.select "activate", [ code ], (results) ->
      if results.affectedRows != 0
        database.select "dropActivationLocalUser", [ localUser.machineId, localUser.id ], (results) ->
          database.select "dropApplicationLocalUser", [ localUser.machineId, localUser.id ], (results) ->
            account(code)

  account = (code) ->
    database.select "getActivationByCode", [ code ], "activation", (results) ->
      activation = results.shift()
      database.select "insertAccount", [ activation.email, activation.sshKey ], (results) ->
        database.select "insertApplication", [ results.insertId, 1 ], (results) ->
          database.fetchLocalUser results.insertId, (localUser) ->
            database.enqueue localUser.machine.hostname, [
              [ "user:create", [ localUser.id ] ],
              [ "user:restorecon", [ localUser.id ] ],
              [ "user:decommission", [ localUser.id ] ],
              [ "user:provision", [ localUser.id ] ],
              [ "user:restorecon", [ localUser.id ] ],
              [ "user:skel", [ localUser.id, "protected" ] ],
              [ "user:authorize", [ localUser.id ] ],
              [ "user:restorecon", [ localUser.id ] ],
              [ "user:group", [ localUser.id, "protected" ] ],
              [ "user:chown", [ localUser.id ] ]
            ]
            process.stdout.write "Activation successful. Welcome to Puppy.\n"

  shell.stdin 33, (error, stdin) ->
    throw error if error
    authorize(hostname, stdin.substring(0, 32))
