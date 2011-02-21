format = require("./puppy").format
module.exports.command =
  description: "List all applications visible to the current account."
  registered: true
  execute: (configuration) ->
    configuration.private "/puppy/private/bin/app_list", [], (command) ->
      command.assert (stdout) ->
        response = JSON.parse(stdout)
        if response.error
          process.stdout.write "error: #{response.message}\n"
        else
          configuration.output = "list" if configuration.output is "text"
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
