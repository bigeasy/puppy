exec = require("child_process").exec
fs = require "fs"

module.exports.command = (bin, argv) ->
  applicationId = argv.shift()
  pid = fs.readFileSync("/var/run/haproxy#{applicationId}.pid", "utf8")
  pid = pid.substring(0, pid.length - 1)
  exec "/bin/kill #{pid}", (error) -> throw error if error
