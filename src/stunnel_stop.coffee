exec = require("child_process").exec
fs = require "fs"

module.exports.command = (argv) ->
  pid = fs.readFileSync("/var/run/stunnel.pid", "utf8")
  pid = pid.substring(0, pid.length - 1)
  exec "/bin/kill #{pid}", (error) -> throw error if error
