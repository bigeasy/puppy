{OptionParser}  = require "coffee-script/optparse"
{Configuration,invoke,app} = require "./puppy"
fs = require "fs"

module.exports.command =
  description: "Deploy an application to Puppy."
  application: true
  execute: (configuration) ->
    try
      stat = fs.statSync "./server.js"
    catch e
      if process.binding("net").ENOENT is e.errno
        process.stdout.write "No server.js found: this does not appear to be a project directory.\n"
        process.exit 1

    if not stat.isFile()
      process.stdout.write "server.js is not a file: this does not appear to be a project directory.\n"
      process.exit 1

    if require("./location").server
      configuration.abend "puppy app:push does not run on the server."

    prepare = configuration.there configuration.application, "/puppy/protected/bin/app_prepare", []
    prepare.assert ->
      localUser = configuration.application.localUsers[0]
      excludeFrom = "#{__dirname}/../etc/rsync.exclude"
      rsync = configuration.here "/usr/bin/rsync", [
        "--exclude=configuration.json", "--exclude-from=#{excludeFrom}", "--delete", "-aqz", "-e", "/usr/bin/ssh",
        "./", "u#{localUser.id}@#{localUser.machine.hostname}:/home/u#{localUser.id}/.puppy/stage/"
      ]
      rsync.assert ->
        deploy = configuration.thereas configuration.application, "private", "/puppy/private/bin/app_deploy_try", []
        deploy.assert ->
