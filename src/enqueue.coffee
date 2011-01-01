require.paths.unshift("/puppy/lib/node")

# Require Node.js core modules.
fs = require "fs"
spawn = require("child_process").spawn

# Require Puppy command execution and logging.
syslog = new (require("common/syslog").Syslog)({ tag: "enqueue", pid: true })
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
argv = process.argv.slice(2)
hostname = argv.shift()
stdin = process.openStdin()
stdin.setEncoding "utf8"
commands = []
stdin.on "data", (chunk) -> commands.push chunk
stdin.on "end", ->
  # TODO This is looking common. Can I put it in shell?
  # We're explicit about the private key, even though it's in the default location.
  ssh = spawn "/usr/bin/ssh", [ "-i", "/home/enqueue/.ssh/identity", "enqueue@#{hostname}", "/puppy/bin/enqueue_proxy" ]
  stdout = ""
  stderr = ""
  ssh.stdout.on "data", (data) -> stdout += data.toString()
  ssh.stderr.on "data", (data) -> stderr += data.toString()
  ssh.stdin.write(commands.join(""))
  ssh.stdin.end()
  ssh.on "exit", (code) ->
    if code
      syslog.send "err", "ssh exited with code #{code}.", { code, stdout, stderr }
      process.exit code
