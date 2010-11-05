fs = require "fs"
spawn = require("child_process").spawn

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
  get: (key) ->
    @local[key] or @global[key]
  home: (callback) ->
    if not home = @get("home")
      if not email = @get("email")
        throw new Error("Email not configured.")
      command = [ "/home/puppy/bin/public", "account:home", email ]
      public = __dirname + "/../etc/puppy_public"
      ssh = spawn "ssh", [ "-T", "-i", public, "-l", "public", "portoroz.prettyrobots.com" ]
      ssh.stdin.end(JSON.stringify(command))
      home = ""
      ssh.stdout.on "data", (chunk) -> home += chunk.toString()
      ssh.stderr.on "data", (chunk) -> process.stdout.write chunk.toString()
      ssh.on "exit", (code) ->
        if code is 0
          console.log "HOME is #{home}\n"
          callback(home.substring(0, home.length - 1))
        else
          throw new Error("Unable to determine home for #{email}")
    else
      callback(home)

module.exports.Configuration = Configuration
