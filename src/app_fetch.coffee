shell     = new (require("common/shell").Shell)()
database  = new (require("common/database").Database)()
protected = require("./protected")
fs        = require "fs"
exec      = require("child_process").exec

module.exports.command = (bin, argv) ->
  uid = parseInt(process.env["SUDO_UID"], 10) - 10000
  database.getLocalUserAccount uid, (account) =>
    database.select "insertApplication", [ account.id, 0 ], (results) ->
      applicationId = results.insertId
      database.fetchLocalUser applicationId, (localUser) ->
        exec "/usr/bin/ssh -i /home/puppy/.ssh/id_puppy_private puppy@#{localUser.machine.hostname} /usr/bin/sudo #{bin}/private user:create #{localUser.id}", (error) ->
          throw error if error
          database.fetchLocalPort applicationId, localUser.machineId, 1, (localPort) ->
            console.log localPort
            database.select "insertHostname", [ localPort.machineId, localPort.port, "t#{localPort.application.id}.puppy.prettyrobots.com" ], (results) ->
              console.log results
              database.fetchLocalPort applicationId, localUser.machineId, 2, (localPort) ->
                console.log localPort
                exec "/usr/bin/ssh -i /home/puppy/.ssh/id_puppy_private puppy@#{localUser.machine.hostname} /usr/bin/sudo #{bin}/private haproxy:configure #{applicationId}", (error) ->
                  throw error if error
