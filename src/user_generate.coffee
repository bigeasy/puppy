require.paths.unshift("/puppy/common/lib/node")

exec            = require("child_process").exec
fs              = require "fs"
crypto          = require "crypto"
syslog          = new (require("common/syslog").Syslog)({ tag: "policy_generate", pid: true })
shell           = new (require("common/shell").Shell)(syslog)
db              = require("common/database")
{OptionParser}  = require("coffee-script/optparse")

argv            = process.argv.slice 2

policies        = argv.shift()

generate = (database, hostname, machine, localUsers) ->
  createLocalPorts = (localUserId) ->
    database.select "getLocalPorts", [ hostname, localUserId ], "localPort", (results) ->
      if results.length < 7
        database.fetchLocalPort machine.id, localUserId, 1, (localPort) ->
          createLocalPorts(localUserId)
      else
        nextLocalUser()
  createLocalUsers = () ->
    database.select "getLocalUserCount", [ machine.id, 10001, 20000 ], (results) ->
      if results[0].localUserCount < policies
        database.select "nextLocalUser", [ machine.id, 20000 ], (results) =>
          nextLocalUserId = results[0].nextLocalUserId
          database.error = (error) =>
            throw error if error.number isnt 1062
            database.createLocalUser machineId, count, callback
          database.select "insertLocalUser", [ machine.id, nextLocalUserId, 1, 0 ], (results) =>
            createLocalPorts(nextLocalUserId)
      else
        process.stdout.write "Done.\n"
  nextLocalUser = () ->
    if localUsers.length
      localUser = localUsers.shift()
      createLocalPorts(localUser.id)
    else
      createLocalUsers()
  nextLocalUser()

db.createDatabase syslog, (database) ->
  shell.hostname (hostname) ->
    database.select "getMachineByHostname", [ hostname ], "machine", (results) ->
      machine = results.shift()
      database.select "getLocalUsers", [ machine.id, 10001, 20000 ], "localUser", (localUsers) ->
        generate(database, hostname, machine, localUsers)
