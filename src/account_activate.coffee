# Import necessary Node.js libraries.
path = require "path"
fs = require "fs"
spawn = require("child_process").spawn

# Import necessary Puppy libraries.
Configuration = require("./puppy").Configuration

# ### Command Implementation
# The `account:activate` command is invoked by a new registrant after they've
# recieved their registration code via email.
#
#     $ puppy account:regsiter 2c0aa17f0d39731b6276d1cd78500d2b
#
# ----------------------------------------------------------------------------

# The JavaScript dispatch program slices `argv` to the first command line
# argument and passes it in as `args`. 
module.exports.command = (args) ->

  # Load the user configuration, set defaults.
  configuration = new Configuration()

  server = configuration.get("server") or "portoroz.prettyrobots.com"

  delete configuration.local["home"]
  delete configuration.global["home"]

  # Request the host server for the account. Then invoke the account
  # registration command on the host server via SSH using the user's default
  # identity. That is, the identities provided by the SSH configuration or the
  # SSH agent, and not a specific identity.
  configuration.home (home) ->
    [ code ] = args

    stdout = ""
    ssh = spawn "ssh", [ "-T", home, "/puppy/bin/account_activated" ]
    ssh.stdin.end(code)
    ssh.stdout.on "data", (chunk) -> process.stdout.write chunk.toString()
    ssh.stderr.on "data", (chunk) -> process.stdout.write chunk.toString()
    ssh.on "exit", (code) ->
      if code != 0
        process.stdout.write "Unable to activate.\n"
