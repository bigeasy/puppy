{OptionParser}  = require "coffee-script/optparse"
format = require("./puppy").format

module.exports.command =
  description: "Create a new database for an application."
  application: true
  execute: (configuration) ->
    parser = new OptionParser [
        [ "-a", "--alias [NAME]", "database alias" ]
        [ "-e", "--engine [mysql/mongodb]", "database engine" ]
    ]


    usage = """
    usage: puppy [OPTIONS] db:fetch [OPTIONS]

    #{parser.help().replace(/^\s*A/, 'a')}
    description:
      Create a new database for use with a Puppy application. The database can be
      either a MySQL or MongoDB database according to the `--engine` parameter.
      The default engine is MySQL. The `--alias` parameter is used to attach a
      label the database configuration for identification in applications.

      example: puppy --app blog db:fetch --engine mongodb --alias blog
      example: puppy --app cart db:fetch --engine mysql --alias datastore

      see:     puppy db:drop
    """

    try
      options         = parser.parse configuration.options.arguments
    catch e
      configuration.usage "Invalid parameters. See usage.", usage

    engine = options.engine or "mysql"
    engine = engine.toLowerCase()
    if not /^mysql$/.test(engine)
      configuration.usage "Invalid database engine. Must be either mysql or mongodb.", usage

    alias = options.alias or engine
    if not /^[-_.\w\d]+$/.test(alias)
      configuration.usage """
        Invalid database alias. Must be less than 32 characters.
               Only period, hyphen and underscore allowed for punctuation.
      """, usage

    configuration.delegate "/puppy/bin/db_fetch", [ configuration.application.id, engine, alias ], (command) ->
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
              dataStores = [[
                "Account", "AppId", "DatabaseId", "Status"
              ]]
              for dataStore in response.dataStores
                dataStores.push [ dataStore.application.account.email, "#{dataStore.application.id}", "d#{dataStore.id}", dataStore.status ]
              process.stdout.write format(dataStores)
            when "text"
              dataStore = response.dataStores[0]
              process.stdout.write "Created database d#{dataStore.id} for application t#{dataStore.application.id}.\n"
