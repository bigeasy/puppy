fs = require "fs"
sys = require "sys"
{spawn,exec} = require("child_process")

class Configuration
  constructor: ->
    home = process.env["HOME"]
    try
      @global = JSON.parse(fs.readFileSync("#{home}/.puppy"))
    catch e
      throw e if process.binding("net").ENOENT isnt e.errno
      @global = {}
    try
      @local = JSON.parse(fs.readFileSync("./.puppy"))
    catch e
      throw e if process.binding("net").ENOENT isnt e.errno
      @local = {}
    @global.server or= "portoroz.prettyrobots.com"
    @dirty = {}

  # Write a map of properties to the global property map. This marks the global
  # property map dirty so that it will be written in a call to `save`. A `null`
  # value will cause the property to be deleted from the global property map.
  setGlobal: (properties) ->
    for k, v of properties
      if v is null
        delete @global[k]
      else
        @global[k] = v
    @dirty.global = true

  # Write the local and global property maps, if they are dirty.
  save: ->
    if @dirty.global
      pretty = JSON.stringify(@global)
      fs.writeFileSync("#{process.env["HOME"]}/.puppy", pretty, "utf8")

  # Get the value associated with the key looking first in the local property
  # map, then in the global property map. Returns undefined if the property is
  # not found.
  get: (key) ->
    @local[key] or @global[key]

  home: (callback) ->
    if not home = @get("home")
      if not email = @get("email")
        throw new Error("Email not configured.")
      public = "#{__dirname}/../etc/public.pub"
      ssh = spawn "ssh", [ "-T", "-i", public, "-l", "public", @get("server") ]
      ssh.stdin.end(JSON.stringify([ "/puppy/bin/account_home", email ]))
      home = ""
      ssh.stdout.on "data", (chunk) -> home += chunk.toString()
      ssh.stderr.on "data", (chunk) -> process.stdout.write chunk.toString()
      ssh.on "exit", (code) ->
        if code is 0
          callback(home.substring(0, home.length - 1))
        else
          throw new Error("Unable to determine home for #{email}")
    else
      callback(home)

module.exports.Configuration = Configuration

module.exports.delegate = (command, splat...) ->
  if require("./location").server
    exec "/bin/hostname", (error, stdout) ->
      throw error if error
      hostname = stdout.substring(0, stdout.length - 1)
      parameters = [ "-H", "-u", "delegate", command, hostname ]
      for parameter in splat
        parameters.push(parameter)
      sudo = spawn "/usr/bin/sudo", parameters
      stdout = ""
      stderr = ""
      sudo.stdout.on "data", (chunk) -> stdout += chunk.toString()
      sudo.stderr.on "data", (chunk) -> stderr += chunk.toString()
      sudo.on "exit", (code) ->
        if code
          console.log stderr if code
        else if stdout.length
          process.stdout.write stdout
  else
    configuration = new Configuration()
    configuration.home (home) ->
      console.log home

      command = argv.slice(0)

      command.unshift("app:fetch")
      command.unshift("/home/puppy/bin/puppy")

      ssh = spawn "ssh", [ "-T", home, "/usr/bin/sudo", "/puppy/bin/app_fetch" ]
      ssh.stdout.on "data", (chunk) -> process.stdout.write chunk.toString()
      ssh.stderr.on "data", (chunk) -> process.stdout.write chunk.toString()
      ssh.on "exit", (code) ->
        if code != 0
          process.stdout.write "Unable to create application.\n"
