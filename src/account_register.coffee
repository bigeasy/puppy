path = require "path"
fs = require "fs"
spawn = require("child_process").spawn

module.exports.command = (argv) ->
  # Not actually used.
  #configuration = JSON.parse(fs.readFileSync("~/.puppy", "utf8"))

  public = __dirname + "/../etc/puppy_public"
  process.exit 1 if argv.length != 2

  [ email, sshKey ] = argv
  sshKey = fs.readFileSync(sshKey, "utf8")
  sshKey = sshKey.substring(0, sshKey.length - 1)
  command = [ "/home/puppy/bin/public", "account:register", email, sshKey ]

  ssh = spawn "ssh", [ "-i", public, "-l", "public", "portoroz.prettyrobots.com", "/home/public/bin/public" ]
  ssh.stdin.end(JSON.stringify(command))
  ssh.stdout.on "data", (chunk) -> process.stdout.write chunk.toString()
  ssh.stderr.on "data", (chunk) -> process.stdout.write chunk.toString()
