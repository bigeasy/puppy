format = require("./puppy").format

module.exports.command =
  description: "List databases for an account or application."
  application: true
  account: true
  execute: (configuration) ->
    params = []
    params.push configuration.application.id unless configuration.application.isHome
    configuration.private "/puppy/private/bin/db_list_try", params, (command) ->
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
                "Account", "AppId", "DatabaseId", "Alias", "Status"
              ]]
              for dataStore in response.dataStores
                dataStores.push [
                  dataStore.application.account.email
                  "t#{dataStore.application.id}"
                  "d#{dataStore.id}"
                  dataStore.alias
                  dataStore.status
                ]
              process.stdout.write format(dataStores)
