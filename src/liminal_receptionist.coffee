require.paths.unshift("/puppy/common/lib/node")

{spawn,exec} = require("child_process")
syslog = new (require("common/syslog").Syslog)({ tag: "unregistered_receptionist", pid: true })
shell = new (require("common/shell").Shell)(syslog)

shell.hostname (hostname) ->
  shell.stdin 33, (error, code) ->
    throw error if error

    if process.env["SSH_ORIGINAL_COMMAND"] != "/puppy/protected/bin/account_activated"
      syslog.send "err", "Invalid command #{process.env["SSH_ORIGINAL_COMMAND"]}.", {}
      process.exit(1)

    command = [ "-u", "private", "/puppy/private/bin/account_activate", hostname ]
    syslog.send "info", "Executing #{command[2]} as delegate.", { command }
    stderr = ""
    activate = spawn "/usr/bin/sudo", command
    activate.stdin.write(code)
    activate.stdin.end()
    activate.stdout.on "data", (chunk) -> process.stdout.write(chunk.toString())
    activate.stderr.on "data", (chunk) -> stderr += chunk.toString()
    activate.on "exit", (code) ->
      if code || stderr.length
        syslog.send "err",
          "Recieved unexpected error messages with exit code " + code + ".", { stderr, code }
      process.exit(code)
