# Require Puppy command execution and logging.
syslog  = new (require("common/syslog").Syslog)({ tag: "enqueue_proxy", pid: true })
shell   = new (require("common/shell").Shell)(syslog)

# This simple proxy maybe something that we can wrap up for reuse.
module.exports.command = ->
  commands = []
  stdin = process.openStdin()
  stdin.setEncoding "utf8"
  stdin.on "data", (chunk)-> commands.push chunk
  stdin.on "end", ->
    shell.doas "worker", "/opt/bin/job", [], commands.join(""), ->
