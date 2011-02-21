path = require "path"
fs = require "fs"
spawn = require("child_process").spawn

Configuration = require("./puppy").Configuration

usage = '''
usage: puppy account:register [email] [ssh public key file]

  Create a new account with Puppy. Initiates registration process by recording
  your email address and public SSH key. A confirmation command is sent to the
  email address provided.

  example: puppy account:register alan@prettyrobots.com ~/.ssh/identity.pub


'''

module.exports.command =
  description: "Create a new Puppy account."
  execute: (configuration) ->
    server = configuration.get("server") or "portoroz.prettyrobots.com"

    public = __dirname + "/../etc/public.pub"

    [ email, sshKey ] = configuration.options.arguments
    if not email or not sshKey
      configuration.abend "\nerror: Required parameters missing. See usage.\n\n#{usage}"

    if not /[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+(?:[A-Z]{2}|com|org|net|edu|gov|mil|biz|info|mobi|name|aero|asia|jobs|museum)\b/.test(email)
      configuration.abend "\nerror: Invalid email address.\n\n#{usage}"

    sshKey = fs.readFileSync(sshKey, "utf8")
    sshKey = sshKey.substring(0, sshKey.length - 1)

    [type, key, comment, rest] = sshKey.split /\s+/
    if rest or not (type and key and comment) or not /^AAAAB3NzaC1yc2EA/.test(key)
      configuration.abend "\nerror: Invalid public ssh key.\n\n#{usage}"

    ssh = spawn "ssh", [ "-T", "-i", public, "-l", "public", server ]
    ssh.stdin.end(JSON.stringify([ "/puppy/private/bin/account_register", email, sshKey ]))
    ssh.stdout.on "data", (chunk) -> process.stdout.write chunk.toString()
    ssh.stderr.on "data", (chunk) -> process.stdout.write chunk.toString()
    ssh.on "exit", (code) ->
      configuration.setGlobal({ email })
      configuration.save()
      process.exit code
