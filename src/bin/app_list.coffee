require("exclusive").createSystem __filename, "hostname, account", (system, hostname, account) ->
  system.sql "getApplications", [ account.id ], "application", (applications) ->
    for application in applications
      application.status = if application.ready then "ready" else "pending"
    process.stdout.write JSON.stringify({
      error: false
      applications
    }, null, 2)
