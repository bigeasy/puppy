path = require "path"
fs = require "fs"
spawn = require("child_process").spawn
Configuration = require("./puppy").Configuration

module.exports.command = (argv) ->
  configuration = new Configuration()

  configuration.home (home) ->
    console.log home

    command = argv.slice(0)

    command.unshift("app:fetch")
    command.unshift("/home/puppy/bin/puppy")

    ssh = spawn "ssh", [ "-T", home, "/usr/bin/sudo", "/puppy/bin/app_fetch" ]
    ssh.stdout.on "data", (chunk) -> process.stdout.write chunk.toString()
    ssh.stderr.on "data", (chunk) -> process.stdout.write chunk.toString()
    ssh.on "exit", (code) ->
      if code != 0
        process.stdout.write "Unable to create application.\n"
