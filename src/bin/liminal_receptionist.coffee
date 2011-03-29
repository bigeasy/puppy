require("common").createShell __filename, (shell) ->
  if process.env["SSH_ORIGINAL_COMMAND"] != "/puppy/protected/bin/account_activated"
    shell.syslog.send "err", "Invalid command #{process.env["SSH_ORIGINAL_COMMAND"]}.", {}
    process.exit 1

  command = shell.runAs "private", "/puppy/private/bin/account_activate", { customFds: [ 0, 1, -1 ] }
  command.run (outcome) ->
    if outcome.code or outcome.stderr?
      shell.syslog.send "err", "Recieved unexpected error messages.", outcome
      process.exit outcome.code or 1
