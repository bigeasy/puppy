path = require "path"
fs = require "fs"
spawn = require("child_process").spawn

Configuration = require("./puppy").Configuration

module.exports.command = (argv) ->
  configuration = new Configuration()
  server = configuration.get("server") or "portoroz.prettyrobots.com"

  public = __dirname + "/../etc/public.pub"
  process.exit 1 if argv.length != 2

  [ email, sshKey ] = argv
  sshKey = fs.readFileSync(sshKey, "utf8")
  sshKey = sshKey.substring(0, sshKey.length - 1)

  ssh = spawn "ssh", [ "-T", "-i", public, "-l", "public", server ]
  ssh.stdin.end(JSON.stringify([ "/puppy/bin/account_register", email, sshKey ]))
  ssh.stdout.on "data", (chunk) -> process.stdout.write chunk.toString()
  ssh.stderr.on "data", (chunk) -> process.stdout.write chunk.toString()
  ssh.on "exit", (code) ->
    configuration.setGlobal({ email })
    configuration.save()
    process.exit code
