exec      = require("child_process").exec
shell     = new (require("common/shell").Shell)()
database  = new (require("common/database").Database)()

module.exports.command = (bin, argv) ->
  authorize = (code) ->
    exec "/bin/hostname", (error, stdout) ->
      if error
        console.log error
        throw new Error("Cannot get hostname.")
      hostname = stdout.substring(0, stdout.length - 1)
      database.select "getLocalUserByActivationCode", [ code ], "localUser", (results) ->
        process.exit 1 unless results.length
        localUser = results.shift()
        console.log process.env
        process.exit 1 unless localUser.machine.hostname is hostname
        process.exit 1 unless localUser.id + 10000 is parseInt(process.env['SUDO_UID'], 10)
        console.log "ACTIVATING"
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
            exec "/usr/bin/ssh -i /home/puppy/.ssh/id_puppy_private puppy@#{localUser.machine.hostname} /usr/bin/sudo #{bin}/private user:create 1", (error) ->
              throw error if error

  stdin = process.openStdin()
  code = ""
  stdin.on "data", (chunk) -> code += chunk.toString()
  stdin.on "end", -> authorize(code)
