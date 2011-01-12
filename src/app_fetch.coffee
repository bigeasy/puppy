path = require "path"
fs = require "fs"
{spawn,exec} = require("child_process")
Configuration = require("./puppy").Configuration

module.exports.command = (argv) ->
  if require("./location").server
    sudo = spawn "/usr/bin/sudo", [ "-H", "/puppy/bin/app_fetch" ]
    stdout = ""
    stderr = ""
    sudo.stdout.on "data", (chunk) -> stdout += chunk.toString()
    sudo.stderr.on "data", (chunk) -> stderr += chunk.toString()
    sudo.on "exit", (code) ->
      console.log code
      console.log stdout
      console.log stderr
  else
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
