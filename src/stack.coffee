#### Node Stack
# Manage your own Node.js stack from your command line.

# Require Node.js core libraries.
fs              = require "fs"
sys             = require "sys"
{exec, spawn}   = require "child_process"

USAGE =
"""
Node Stack management utility.

Usage: stack service:command [arguments]
"""

#### Configuration
# Reads and writes configuration files.
#
# ----------------------------------------------------------------------------

# Export the `Configuration` class.
module.exports.Configuration = class Configuration

  # Create a default configuration if the `~/.node-stack` file does not exist.
  constructor: ->
    @file = "#{process.env["HOME"]}/.node-stack"
    try
      @data = JSON.parse(fs.readFileSync(@file, "utf8"))
    catch _
      @data =
        hosts: {}
        administrator: { name: "node", uid: 707, group: "node", gid: 707 }
  save: ->
    fs.writeFileSync(@file, JSON.stringify(@data), "utf8")

#### class LocalShell
# Implements command shell on the calling machine.
#
# ----------------------------------------------------------------------------

# Not exported, the local shell is created and passed to service actions. 
class Local
  # Construct a local command shell.
  constructor: ->
    @sudo = new LocalSuperUser()

  # Local script execution calls the interpreter directly.
  script: (splat...) ->
    script.apply null, splat

# The super user implementation for the local machine.
class LocalSuperUser
  # Local script execution calls the interpreter directly.
  script: (splat...) ->
    splat.unshift("sudo")
    script.apply null, splat

#### class RemoteShell
# Implements command shell on the remote machine.
#
# ----------------------------------------------------------------------------

# Implements command shell on the remote machine.
module.exports.Remote = class Remote
  constructor: (@host, @user) ->
    @sudo = new RemoteSuperUser(@host, @user)

  # Local script execution calls the interpreter directly.
  script: (splat...) ->
    splat.unshift("ssh", "-l", @user, @host)
    script.apply null, splat

class RemoteSuperUser
  constructor: (@host, @user) ->

  # Local script execution calls the interpreter directly.
  script: (splat...) ->
    splat.unshift("sudo") if @user isnt "root"
    splat.unshift("ssh", "-l", @user, @host)
    script.apply null, splat

#### command()
# Implements the command line interface.
#
# ----------------------------------------------------------------------------

# Called from the excutable script.
command = ->
  # Read the current configuration.
  configuration = new Configuration()

  # If the first argument is not an action, then it is the name of a remote
  # machine or a machine group.
  if not /:/.test(process.argv[0])
    candidates = []
    for candidate, definition of configuration.data.hosts
      if candidate is process.argv[0]
        host = candidate
      else if /^#{process.argv[0]}\./.test(candidate)
        host = candidate
      if host
        process.argv.shift()
        break

  # Determine the service and action. Split the qualified action name. Load the
  # serivce using require, reporting an error if the service or action does not
  # exist.
  qualified = /^(.*):(.*)$/.exec(process.argv.shift() || "")

  return 1 if not qualified
  try
    service   = require("../services/#{qualified[1]}")
  catch _
    console.log _
    return 1
  action    = qualified[2]
  return 1 if not service.actions[action]

  # Create the local and remote command shells.
  local   = new Local()
  remote  = new Remote(host, configuration.data.administrator.name)

  # If the service has a local command interpreter, invoke it.
  if service.Client
    client = new (service.Client)()
    if typeof client[action] == "function"
      client[action](local, remote)

  # If the service has a remote command interpreter, invoke it.
  if service.Server
    client = new (service.Server)()
    if typeof client[action] == "function"
      client[action](local, remote)

run = (coffee, service, qualified) ->
  args = []
  args.push "-E", coffee, service, qualified[2]
  for arg in process.argv
    args.push arg
  child = spawn "sudo", args
  stdin = process.openStdin()
  sys.pump(stdin , child.stdin)
  child.stdout.on "data", (data) -> process.stdout.write data
  child.stderr.on "data", (data) -> process.stdout.write data
  child.on "exit", -> stdin.pause()

module.exports.command = command

module.exports.script = script = (splat...) ->
  callback = splat.pop()
  source = splat.pop()
  splat = [ splat[0], splat.splice(1) ]
  program = spawn.apply null, splat
  stdout = ""
  stderr = ""
  program.stdout.on "data", (data) ->
    stdout += data
  program.stderr.on "data", (data) ->
    stderr += data.toString()
  program.on "exit", (code) ->
    callback(code, stdout, stderr)
  program.stdin.write(source)
  program.stdin.end()

module.exports.execute = execute = (splat...) ->
  if typeof splat[splat - 1] == "function"
    callback = splat.pop()
  else
    callback = ->
  splat.push (error, stdout, stderr)->
    throw error if error
    callback(stdout, stderr)
  exec.apply null, splat

module.exports.readSecret = (prompt, callback) ->
  process.stdout.write prompt
  execute "stty -g", (modes) ->
    execute "stty -noecho", ->
      response = ""
      stdin = process.openStdin()
      stdin.setEncoding "utf8"
      stdin.on "data", (chunk) ->
        response += chunk
        secret = /^\s*(.*)\s*\n$/.exec chunk
        if secret
          stdin.pause()
          execute "stty " + modes, ->
            callback secret[1]
