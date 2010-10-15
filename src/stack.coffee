#### Node Stack
# Manage your own Node.js stack from your command line.

# Require Node.js core libraries.
fs              = require "fs"
sys             = require "sys"
path            = require "path"
{exec, spawn}   = require "child_process"

# Bash functions to include in heredoc bash programs.
module.exports.bash =
  functions: """
  # [Node Stack History]
  node_stack_count=0

  function stack_check_reboot ()
  {
      if [ -e /var/run/reboot-required ]
      then
          echo "[Node Stack Reboot] Reboot is requried. Rebooting."
          /sbin/shutdown -r now
          exit 0
      fi
  }

  function stack_install ()
  {
      package=$1
      if stack_missing $package
      then
          stack_history "Installing $package."
          stack_try apt-get install -y $package
      fi
  }

  function stack_missing ()
  {
      package=$1
      installed=$(dpkg --list | awk '{ print $2 }' | grep '^'$package'$')
      if [ "x-$installed" == "x-$package" ]
      then
        return 1
      fi
  }

  function stack_history ()
  {
      echo "[$(date --iso-8601=seconds)] $1"
  }

  function stack_try ()
  {
      eval $@
      if [ $? -ne 0 ]
      then
          echo "[Node Stack Fatal] Unable to execute: $@"
          exit 1
      fi
  }
  """

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
    @file = "#{process.env["HOME"]}/.node-stack/configuration"
    try
      @data = JSON.parse(fs.readFileSync(@file, "utf8"))
    catch _
      @data =
        hosts: {}
        administrator: { name: "node", uid: 707, group: "node", gid: 707 }

  # Save the configuration, then call the given callback.
  save: (callback) ->
    exec "mkdir -p #{path.dirname(@file)}", (error) =>
      throw error if error
      fs.writeFileSync(@file, JSON.stringify(@data), "utf8")
      callback() if callback

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
    service   = require("./#{qualified[1]}")
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

# Detects message indented to be logged as part of the history or else reported
# back to the user to indicate their progress. Any pattern chosen to deliniate
# messages needs to be *distinct enough*. Anything we choose could be in the
# output, but we have a very good idea of what the output will be and the worst
# case it that we add a line of curiosity to the logs.
class History
  constructor: ->
    @entry = -1
    @error = -1

  progress: (data) ->
    entries = data.match(/^\[\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[-+]\d{4}\]\s.*$/mg)
    for entry, i in entries or []
      if @entry < i
        @entry = i
        process.stdout.write(entry + "\n")
    errors = data.match(/^\[Node Stack Fatal]\s.*$/mg)
    for error, i in errors or []
      if @error < i
        @error = i
        process.stdout.write("#{error}\n")

# A minimal progress indicator so that I don't go mad waiting with no feedback
# for a script to run. You can make these so fancy, but it is hard for us,
# because we are keeping it simple, simply running other programs, and obtaining
# a true measure of progress means make it no longer simple. Running apt-get,
# for example. I'm tempted to remove this, since the notion of an appliance
# ought to be binary, you install it or you don't, but this is simple.
#
# I get the feeling that, everytime you see this, you are going to want to
# overthink it.
class Indicator
  constructor: (@count) ->
    @seen = 0

  indicator: (message) ->
    seen = @seen.toString()
    while seen.length < @count.toString().length
      seen = "0" + seen
    indicator = "[#{@seen} of #{@count} | #{message}"
    while indicator.length < 77
      indicator += " "
    indicator += "]"
    process.stdout.write("\r" + indicator)

  progress: (data) ->
    while match = /^\[Node Stack Progress #{@seen + 1}\] (.*)$/m.exec(data)
      @seen ++
      @indicator(match[1])
    if not @complete and  match = /^\[Node Stack Progress Complete\] (.*)$/m.exec(data)
      @indicator(match[1])
      @complete = true
      process.stdout.write("\n")

module.exports.script = script = (splat...) ->
  callback = splat.pop()
  source = splat.pop()
  indicator = null
  if /^# \[Node Stack Progress\]$/m.test(source)
    indicator = new Indicator(source.match(/^stack_progress /mg).length)
  splat = [ splat[0], splat.splice(1) ]
  program = spawn.apply null, splat
  stdout = ""
  stderr = ""
  history = new History()
  program.stdout.on "data", (data) ->
    stdout += data
    if indicator
      indicator.progress(stdout)
    history.progress(stdout)
  program.stderr.on "data", (data) ->
    stderr += data.toString()
  program.on "exit", (code) ->
    if indicator
      indicator.progress(stdout)
    history.progress(stdout)
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

# Is has been decided that, any secrets that need to be read are read on the
# client side, in advance of executing the server side, then piped into the
# server side. Install scripts are not chatty or conversant. You can turn off
# the echo on the client side and that ought to be enough.
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
