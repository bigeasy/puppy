path = require "path"
fs = require "fs"
spawn = require("child_process").spawn
Configuration = require("./puppy").Configuration

module.exports.command = (argv) ->
  configuration = new Configuration()

  delete configuration.local["home"]
  delete configuration.global["home"]

  configuration.home (home) ->
    console.log home
    [ code ] = argv

    ssh = spawn "ssh", [ "-T", home ]
    ssh.stdin.end(code)
    ssh.stdout.on "data", (chunk) -> process.stdout.write chunk.toString()
    ssh.stderr.on "data", (chunk) -> process.stdout.write chunk.toString()
    ssh.on "exit", (code) ->
      if code is 0
        process.stdout.write "Activation successful. Welcome to Puppy.\n"
      else
        process.stdout.write "Unable to activate.\n"
