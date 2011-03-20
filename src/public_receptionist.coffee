# Require the common Puppy libraries.
require.paths.unshift("/puppy/common/lib/node")

# Import packages.
{helpers: {flatten}}  = require "coffee-script"
{spawn}             = require "child_process"
{Syslog}            = require "common"

# Create a syslog to record the event.
syslog = new (Syslog)({ tag: "public_receptionist", pid: true })

# Command is sent through stdin so arguments do not appear in `ps`.
body = ""
stdin = process.openStdin()
stdin.on "data", (chunk) ->
  body += chunk.toString()
  if body.length > 1024 * 16
    process.exit 1

log = (message, context) ->
  syslog.send "err", message, context, -> process.exit context.code

# When stdin is closed we spring into action, parsing the body of the message,
# checking that it is a valid public command, and running the command.
stdin.on "end", ->
  # Output in event of error.
  env = process.env

  # Parse the command.
  command = JSON.parse(body)

  # Take note of request.
  syslog.send "info", "Executing public request.", { command }

  # There are only two programs that can be publically run.
  if ! /^\/puppy\/private\/bin\/account_(register|home)$/.test(command[0])
    syslog.send "err", "Public called with invalid command.", { command, env }
    process.exit 1

  # Execute command and send to standard out.
  stderr = ""
  public = spawn "/usr/bin/sudo", flatten([ "-u", "private", command ])
  public.stdout.on "data", (chunk) -> process.stdout.write(chunk.toString())
  public.stderr.on "data", (chunk) -> stderr += chunk.toString()
  public.on "exit", (code) ->
    if code
      log("Public execution received error exit.", { command, stderr, code, env })
    if stderr.length
      log("Public execution received error output.", { command, stderr, code, env })
