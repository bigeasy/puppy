format = require("./puppy").format

module.exports.command =
  description: "Create a new application."
  execute: (configuration) ->
    configuration.delegate "/puppy/bin/app_fetch", [], (command) ->
      command.assert (stdout) ->
        response = JSON.parse(stdout)
        if response.error
          process.stdout.write "error: #{response.message}\n"
        else
          switch configuration.output
            when "json"
              process.stdout.write stdout
              process.stdout.write "\n"
            when "list"
              applications = [[
                "Account", "AppId", "Status"
              ]]
              for application in response.applications
                applications.push [ application.account.email, "t#{application.id}", application.status ]
              process.stdout.write format(applications)
            when "text"
              process.stdout.write "Created application t#{response.applications[0].id}.\n"
