fs = require "fs"
{spawn} = require("child_process")

module.exports.command =
  description: "Execute a MySQL shell."
  application: true
  execute: (configuration) ->
    if require("./location").server
      console.log "Local execution of mysql:prompt is not implemented."
      process.exit 1
    else
      tty = false
      for fd in [0...2]
        if (fs.fstatSync(0).isCharacterDevice())
          tty = true
          break
      localUser = configuration.application.localUsers[0]
      program = spawn "/usr/bin/ssh", [ (if tty then "-t" else "-T"), "-q", "-l", "u#{localUser.id}", localUser.machine.hostname, "/puppy/protected/bin/node_path", "/puppy/protected/bin/mysql_prompt" ], { customFds: [ 0, 1, 2 ] }
      program.on "exit", (code) -> process.exit code
