require.paths.unshift("/puppy/lib/node")

spawn = require("child_process").spawn
body = ""
syslog = new (require("common/syslog").Syslog)({ tag: "public_proxy", pid: true })

stdin = process.openStdin()
stdin.on "data", (chunk) ->
  body += chunk.toString()
  if body.length > 1024 * 16
    process.exit(1)

stdin.on "end", ->
  command = JSON.parse(body)
  process.stdout.write "Hello, World!\n"
  process.stdout.write body

  if ! /^\/puppy\/bin\/(account_register|account_home)$/.test(command[0])
    syslog.send "err", "Invalid command #{command[0]}.", {}
    process.exit(1)

  command.unshift "delegate"
  command.unshift "-u"

  process.stdout.write "Hello, World!\n"

  syslog.send "info", "Executing public request.", { command }
  stderr = []
  public = spawn "/usr/bin/sudo", command
  public.stdout.on "data", (chunk) -> process.stdout.write(chunk.toString())
  public.stderr.on "data", (chunk) -> stderr.push(chunk.toString())
  public.on "exit", (code) ->
    if code || stderr.length
      syslog.send "err",
        "Recieved unexpected error messages with exit code " + code + ".",
        { stderr: stderr.join(""), code: code }
    process.exit(code)
