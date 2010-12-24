# Require Node.js core modules.
fs = require "fs"

# Require Puppy command execution and logging.
syslog = new (require("common/syslog").Syslog)({ tag: "job", pid: true })
shell = new (require("common/shell").Shell)(syslog)

# Need to set a limit to the size of the incoming buffer. It should never be
# more than a kilobyte, so at 4K and we need to report an attack.
#
# We could check against the database to see if someone has the ability to
# perform the command, based on the original uid requesting the command.
#
# When evil is sent to enqueue, we need to write the bad data, at least the
# first 4K of it, to a file where we can inspect it.
#
# Ideally, any request to the system would aduit the request through all of its
# transitions. Ideally, there would be a real model, which might be preferable
# to sifting through a morass of log files.
#
# The error level should trigger an audit by the system administrator.
module.exports.command = ->
  file = "/var/spool/puppy/#{process.pid}-#{new Date().getTime()}"
  stdin = process.openStdin()
  stdin.setEncoding "utf8"
  commands = []
  stdin.on "data", (chunk) -> commands.push chunk
  stdin.on "end", ->
    commands = commands.join ""
    for line in commands.split /\n/
      continue if /^\s*$/.test(line)
      abend = (msg, e) ->
        dump =
          line: line
          stdin: commands.substring(0, 256)
        dump.e = e.message if e
        syslog.send "err", "ERROR: #{msg}", dump
        process.exit 1
      try
        command = JSON.parse line
      catch e
        abend "Invalid JSON line.", e
      if not command.join
        abend "Command is not an array."
      if command.length > 3
        abend "Command array is too long."
      if command.length == 0
        abend "Command array is empty."
      if command.length != 1 and not command[1].join
        abend "Command arguments must be contained in array."
      syslog.send "info", "Queued command #{command[0]}.", { command }
    fs.writeFileSync "#{file}.tmp", commands, "utf8"
    fs.renameSync "#{file}.tmp", file
