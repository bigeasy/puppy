format = require("./puppy").format

module.exports.command =
  description: "Create a new database for an application."
  application: true
  execute: (configuration) ->
    configuration.delegate "/puppy/bin/db_list", [ configuration.application.id ], (command) ->
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
              dataStores = [[
                "Account", "AppId", "DatabaseId", "Status"
              ]]
              for dataStore in response.dataStores
                dataStores.push [
                  dataStore.application.account.email
                  "t#{dataStore.application.id}"
                  "d#{dataStore.id}"
                  dataStore.status
                ]
              process.stdout.write format(dataStores)
