{Configuration} = require "./puppy"
{OptionParser}  = require "coffee-script/lib/optparse"
fs              = require "fs"
path            = require "path"

parser = new OptionParser [
  [ "-a", "--app [NAME]", "application name" ]
  [ "-l", "--list", "display listing output" ]
  [ "-j", "--json", "display json output" ]
  [ "-q", "--quiet", "display no output" ]
  [ "-h", "--help", "display puppy help" ]
]

class Usage
  constructor: (@message) ->
    process.stdout.on "drain", ->
      process.exit if @message then 1 else 0
  explain: ->
    commands = []
    width = 0
    for file in (fs.readdirSync(__dirname).filter (file) -> /_/.test(file))
      command = file.replace /\.js$/, ""
      description = require("../lib/#{command}").command.description
      if description
        command = command.replace /_/, ":"
        width = command.length if width < command.length
        commands.push [ command, description ]
    width++ if width % 4 is 0
    width = 4 * Math.floor((width + 3) / 4)
    descriptions = []
    for command in commands
      descriptions.push "  #{command[0]}#{new Array(width - command[0].length).join(" ")}#{command[1]}"
    error = if not @message then "" else """

    error: #{@message}

    """
    process.stdout.write """
    #{error}
    usage: puppy [OPTIONS] [COMMAND] [OPTIONS]

    #{parser.help().replace(/^\s*Available/, 'puppy')}
    description:
      Invoke a Puppy command. Most commands accept an `--app` parameter that
      identifies the application to use by identifier or alias. Some commands are
      global and do not require an `--app` parameter, but will accept one anyway.

    available commands:
    #{descriptions.join "\n"}


    """

module.exports.command = (argv) ->
  try
    try
      options         = parser.parse process.argv.slice(2)
    catch e
      throw new Usage "Invalid parameters. See usage."

    if options.help
      throw new Usage()

    if options.arguments.length is 0
      throw new Usage "Command missing. See usage."

    name = options.arguments.shift()
    if not /^\w{1,12}:\w{1,12}$/.test(name)
      throw new Usage "Invalid command name. See usage."
    commandFile = name.replace /:/, "_"

    path.exists "#{__dirname}/#{commandFile}.js", (exists) ->
      if not exists
        throw new Usage "Unknown command `#{name}`. See usage."
      configuration = new Configuration(parser, options)
      command = require("./#{commandFile}").command
      if command.registered or command.application or command.account
        configuration.applications (applications) =>
          if options.app
            if /^\d+$/.test(options.app)
              appId = parseInt options.app, 10
            else
              id = /^t(\d+)$/.exec(options.app)
              appId = if id then parseInt(id[1], 10) else 0
            application = (applications.filter (application) -> application.id is appId).shift()
          else
            application = (applications.filter (application) -> application.isHome).shift()
          if (not command.account) and (command.application and application.isHome)
            throw new Usage "No application specified."
          configuration.application = application
          command.execute(configuration)
      else
        command.execute(configuration)
  catch e
    if e.explain then e.explain() else throw e
