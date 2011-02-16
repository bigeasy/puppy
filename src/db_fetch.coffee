{OptionParser}  = require "coffee-script/optparse"

module.exports.command =
  description: "Create a new database for an application."
  execute: (configuration) ->
    parser = new OptionParser [
        [ "-a", "--alias [NAME]", "database alias" ]
        [ "-e", "--engine [mysql/mongodb]", "database engine" ]
    ]


    usage = """
    usage: puppy account:activate [activation code]

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
      options         = parser.parse process.argv.slice(2)
    catch e
      configuration.usage "Invalid parameters. See usage.", usage

    configuration.delegate "/puppy/bin/db_fetch", configuration.options.arguments
