path = require "path"
fs = require "fs"
spawn = require("child_process").spawn

module.exports.command = (argv) ->
  try
    configuration = JSON.parse(fs.readFileSync("#{process.env["HOME"]}/.puppy", "utf8"))
  catch e
    configuration = {}

  configuration.server or= "portoroz.prettyrobots.com"

  public = __dirname + "/../etc/public.pub"
  process.exit 1 if argv.length != 2

  [ email, sshKey ] = argv
  sshKey = fs.readFileSync(sshKey, "utf8")
  sshKey = sshKey.substring(0, sshKey.length - 1)
  command = [ "/opt/bin/public", "account:register", email, sshKey ]

  ssh = spawn "ssh", [ "-T", "-i", public, "-l", "public", configuration.server ]
  ssh.stdin.end(JSON.stringify(command))
  ssh.stdout.on "data", (chunk) -> process.stdout.write chunk.toString()
  ssh.stderr.on "data", (chunk) -> process.stdout.write chunk.toString()
  ssh.on "exit", (code) ->  process.exit code
