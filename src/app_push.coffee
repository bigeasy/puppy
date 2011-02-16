{OptionParser}  = require "coffee-script/optparse"
{Configuration,invoke,app} = require "./puppy"
fs = require "fs"

parser = new OptionParser [
  [ "-a", "--app [NAME]", "application name" ]
]

usage = ->
  process.stdout.write parser.help()
  process.exit 1

module.exports.command = (argv) ->
  try
    options         = parser.parse argv
  catch e
    usage()

  try
    stat = fs.statSync "./server.js"
  catch e
    if process.binding("net").ENOENT is e.errno
      process.stdout.write "No server.js found: this does not appear to be a project directory.\n"
      process.exit 1

  if not stat.isFile()
    process.stdout.write "server.js is not a file: this does not appear to be a project directory.\n"
    process.exit 1


  configuration = new Configuration()
  if require("./location").server
    configuration.abend "puppy app:push does not run on the server."

  options.app = app(options.app, usage)
  configuration.application options.app, (app) ->
    prepare = configuration.there app, "/puppy/bin/app_prepare", []
    prepare.assert ->
      localUser = app.localUsers[0]
      excludeFrom = "#{__dirname}/../etc/rsync.exclude"
      rsync = configuration.here "/usr/bin/rsync", [
        "--exclude=configuration.json", "--exclude-from=#{excludeFrom}", "--delete", "-aqz", "-e", "/usr/bin/ssh",
        "./", "u#{localUser.id}@#{localUser.machine.hostname}:/home/u#{localUser.id}/.puppy/stage/"
      ]
      rsync.assert ->
        console.log "HERE"
        deploy = configuration.thereas app, "delegate", "/puppy/bin/app_deploy", []
        deploy.assert ->
