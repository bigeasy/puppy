{Configuration} = require "./puppy"
{OptionParser}  = require "coffee-script/optparse"

module.exports.command = (argv) ->
  parser = new OptionParser [
    [ "-a", "--app [NAME]", "application name" ]
  ]

  usage = ->
    process.stdout.write parser.help()
    process.exit 1

  try
    options         = parser.parse process.argv.slice(2)
  catch e
    usage()

  [noun, verb] = options.arguments.shift().split(/:/)
  configuration = new Configuration(options, usage)
  require("../lib/#{noun}_#{verb}").command(configuration)
