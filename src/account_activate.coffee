require.paths.unshift("/puppy/lib/node")

exec      = require("child_process").exec
syslog = new (require("common/syslog").Syslog)({ tag: "account_activate", pid: true })
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
      shell.verify(localUser.id + 10000 is parseInt(process.env["SUDO_UID"], 10),
        "SUDO_UID #{process.env["SUDO_UID"]} does not match #{localUser.id + 10000}.")
      activate(localUser, code)

  activate = (localUser, code) ->
    console.log "ACTIVATING"
    database.select "activate", [ code ], (results) ->
      console.log results
      console.log code
      console.log "ACTIVATED"
      if results.affectedRows != 0
        database.select "dropActivationLocalUser", [ localUser.machineId, localUser.id ], (results) ->
          console.log "DROP"
          console.log results
          database.select "dropApplicationLocalUser", [ localUser.machineId, localUser.id ], (results) ->
            console.log "DROP"
            console.log results
            account(code)

  account = (code) ->
    database.select "getActivationByCode", [ code ], "activation", (results) ->
      console.log results
      activation = results.shift()
      database.select "insertAccount", [ activation.email, activation.sshKey ], (results) ->
        console.log results
        database.select "insertApplication", [ results.insertId, 1 ], (results) ->
          console.log results
          database.fetchLocalUser results.insertId, (localUser) ->
            console.log localUser
            shell.enqueue localUser.machine.hostname,
              [ "user:create", [ localUser.id ] ],
              [ "user:restorecon", [ localUser.id ] ],
              [ "user:decommission", [ localUser.id ] ],
              [ "user:provision", [ localUser.id ] ],
              [ "user:restorecon", [ localUser.id ] ],
              [ "user:skel", [ localUser.id ] ],
              [ "user:authorize", [ localUser.id ] ],
              [ "user:restorecon", [ localUser.id ] ],
              [ "user:group", [ localUser.id, "registered" ] ],
              [ "user:chown", [ localUser.id ] ]
            process.stdout.write "Activation successful. Welcome to Puppy.\n"

  shell.stdin 33, (error, stdin) ->
    throw error if error
    authorize(hostname, stdin.substring(0, 32))
