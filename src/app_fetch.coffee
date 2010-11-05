shell     = new (require("common/shell").Shell)()
database  = new (require("common/database").Database)()
protected = require("./protected")
fs        = require "fs"
exec      = require("child_process").exec

module.exports.command = (bin, argv) ->
  uid = parseInt(process.env["SUDO_UID"], 10) - 10000
  database.getLocalUserAccount uid, (account) =>
    database.select "insertApplication", [ account.id, 0 ], (results) ->
      database.fetchLocalUser results.insertId, (localUser) ->
        console.log localUser
        exec "/usr/bin/ssh -i /home/puppy/.ssh/id_puppy_private puppy@#{localUser.machine.hostname} /usr/bin/sudo #{bin}/private user:create 1", (error) ->
          throw error if error
