# Require the common Puppy libraries.
require.paths.unshift("/puppy/common/lib/node")

# Import packages.
{helpers: {flatten}}  = require "coffee-script"

require("common/public").createShell __filename, (shell) ->
  syslog = shell.syslog

  # Command is sent through stdin so arguments do not appear in `ps`.
  body = ""
  stdin = process.openStdin()
  stdin.on "data", (chunk) ->
    body += chunk.toString()
    if body.length > 1024 * 16
      process.exit 1

  log = (message, context) ->
    syslog.send "err", message, context, -> process.exit context.code or 1

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

    shell.runAs("private", command.shift(), command).run (outcome) ->
      process.stdout.write(outcome.stdout) if outcome.stdout?
      if outcome.code
        log("Public execution received error exit.", outcome)
      if outcome.stderr?
        log("Public execution received error output.", outcome)
