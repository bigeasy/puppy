require.paths.unshift("/puppy/common/lib/node")

exec      = require("child_process").exec
syslog    = new (require("common/syslog").Syslog)({ tag: "account_activate", pid: true })
shell     = new (require("common/shell").Shell)(syslog)
db        = require("common/database")

argv      = process.argv.slice 2

# Choose a machine based on a weighted random where the weights are the
# determined by the number of available machine users with policies.
chooseMachine = (database, callback) ->
  database.select "getMachines", [], "machine", (machines) ->
    machines = machines.filter (machine) -> machine.localUsers >
    machine.localUsersInUse
    for machine in machines
      machine.weight = 1 - (machine.localUsersInUse / machine.localUsers)
    sum = machines.reduce(((sum, machine) -> sum + machine.weight), 0)
    point = Math.random() * sum
    for machine in machines
      if machine.weight >= point
        callback(machine)
        return
      point -= machine.weight
    callback(null)

localUserUnavailable = ->
  syslog.error "Unable to allocate local user account for application."
  process.stdout.write JSON.stringify({
    error: true
    message: "No new application accounts available at this time."
  })
  process.exit 0

fetchLocalUser = (database, account, applicationId, machine) ->
  localUserUnavailable() unless machine
  database.select "fetchLocalUser", [ applicationId, machine.id, 1 ], (results) =>
    if results.affectedRows
      database.select "getLocalUserByAssignment", [ results.insertId ], "localUser", (results) ->
        localUser = results.shift()
        database.enqueue localUser.machine.hostname, [
          [ "user:create", [ localUser.id ] ],
          [ "user:restorecon", [ localUser.id ] ],
          [ "user:decommission", [ localUser.id ] ],
          [ "user:provision", [ localUser.id ] ],
          [ "user:restorecon", [ localUser.id ] ],
          [ "user:skel", [ localUser.id, "protected" ] ],
          [ "user:authorize", [ localUser.id ] ],
          [ "user:config", [ localUser.id ] ],
          [ "user:restorecon", [ localUser.id ] ],
          [ "user:group", [ localUser.id, "protected" ] ],
          [ "user:chown", [ localUser.id ] ]
          [ "init:generate", [ localUser.id ] ]
          [ "init:restorecon", [ localUser.id ] ]
          [ "user:provisioned", [ localUser.id ] ]
        ], ->
          database.select "getLocalPorts", [ localUser.machine.hostname, localUser.id ], "localPort", (localPorts) ->
            localPort = localPorts.shift()
            database.properties (properties) ->
              database.virtualHost "t#{applicationId}.#{properties.applicationHost}", localUser.machine.ip,  localPort.port, ->
                database.select "getApplications", [ account.id ], "application", (results) ->
                  applications = []
                  for application in results
                    if application.id is applicationId
                      application.status = "new"
                      applications.unshift application
                    else
                      application.status = if application.ready is 1 then "ready" else "pending"
                      applications.push application
                  process.stdout.write JSON.stringify({
                    error: false
                    applications
                  })
    else
      chooseMachine database, (machine) ->
        fetchLocalUser(database, account, applicationId, machine)

# Select the machine at random, but there is only one machine for now.
# Check that there are localUsers available on the machine.
db.createDatabase syslog, (database) ->
  uid = parseInt process.env["SUDO_UID"], 10
  shell.verify(uid > 10000, "Inexplicable uid #{uid}")
  shell.hostname (hostname) ->
    chooseMachine database, (machine) ->
      localUserUnavailable() unless machine
      database.select "getAccountByLocalUser", [ hostname, uid ], "account", (results) ->
        account = results.shift()
        database.select "insertApplication", [ account.id, 0 ], (results) ->
          applicationId = results.insertId
          fetchLocalUser(database, account, applicationId, machine)
