# Require Node.js libraries.
fs = require "fs"
sys = require "sys"
path = require "path"
{spawn,exec} = require("child_process")

# Encapsulates a command to invoke using `spawn`.
class Command
  # Create a command with the given `command` and command `parameters`.
  constructor: (@command, @parameters) ->

  # Execute the command and assert a successful error code before invoking the
  # callback.
  assert: (callback) ->
    program = spawn @command, @parameters
    stdout = ""
    stderr = ""
    program.stdout.on "data", (chunk) -> stdout += chunk.toString()
    program.stderr.on "data", (chunk) -> stderr += chunk.toString()
    program.on "exit", (code) ->
      if code is 0
        callback(stdout)
      else
        console.log stderr
        process.exit code

  # Inherit the standard I/O handles of the parent process.
  passthrough: (callback) ->
    program = spawn @command, @parameters, { customFds: [ 0, 1, 2 ] }
    program.on "exit", (code) ->
      if callback
        callback(code)
      else
        process.exit code

class Configuration
  constructor: (@parser, @options) ->
    home = process.env["HOME"]
    try
      fs.statSync "#{home}/.puppy"
      @global = JSON.parse(fs.readFileSync("#{home}/.puppy/configuration.json"))
    catch e
      throw e if process.binding("net").ENOENT isnt e.errno
      @global = {}
    try
      fs.statSync "./.puppy"
      @local = JSON.parse(fs.readFileSync("./.puppy/configuration.json"))
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

  usage: (error, usage) -> @abend "\nerror: #{error}\n\n#{usage}\n\n"

  abend: (message) ->
    process.stdout.write message
    process.exit 1

  # Write the local and global property maps, if they are dirty.
  save: ->
    if @dirty.global
      pretty = JSON.stringify(@global)
      try
        stat = fs.statSync "#{process.env["HOME"]}/.puppy"
        if not stat.isDirectory()
          @abend "#{process.env["HOME"]}/.puppy is not a directory."
        fs.writeFileSync("#{process.env["HOME"]}/.puppy/configuration.json", pretty, "utf8")
      catch error
        throw error if process.binding("net").ENOENT isnt error.errno
        fs.mkdirSync "#{process.env["HOME"]}/.puppy", 0755
        @save()

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

  directory: (callback) ->
    home = process.env["HOME"]
    fs.stat "#{home}/.puppy", (error, stat) =>
      if error
        if process.binding("net").ENOENT is error.errno
          fs.mkdir "#{home}/.puppy", 0755, (error) =>
            throw error if error
            @directory(callback)
        else
          throw error
      callback()

  application: (app, callback) ->
    @applications (applications) ->
      if app
        if /^\d+$/.test(app)
          app = parseInt app, 10
        else
          id = /^t(\d+)$/.exec(app)
          app = if id then parseInt(id[1], 10) else 0
        application = (applications.filter (application) -> application.id is id).shift()
      else
        application = (applications.filter (application) -> application.isHome is 1).shift()
      callback(application)

  applications: (callback) ->
    @directory =>
      try
        home = process.env["HOME"]
        callback(JSON.parse(fs.readFileSync("#{home}/.puppy/applications.json", "utf8")))
      catch error

        if process.binding("net").ENOENT is error.errno
          @fetchApplications (applications) =>
            fs.writeFileSync "#{home}/.puppy/applications.json", JSON.stringify(applications), "utf8"
            @applications(callback)
        else
          throw error

  fetchApplications: (callback) ->
    @home (user) ->
      config = spawn "/usr/bin/ssh", [ "-T", user, "/usr/bin/sudo", "-u", "delegate", "/puppy/bin/account_apps" ]
      stdout = ""
      stderr = ""
      config.stdout.on "data", (chunk) -> stdout += chunk.toString()
      config.stderr.on "data", (chunk) -> stderr += chunk.toString()
      config.on "exit", (code) ->
        if code is 0
          callback(JSON.parse(stdout))
        else
          throw new Error("Unable to list applications.")
  here: (command, parameters) ->
    new Command command, parameters
  thereas: (app, user, command, parameters) ->
    params = [  "-H", "-u", user, command ]
    for param in parameters.slice(0)
      params.push param
    @there(app, "/usr/bin/sudo", params)
  there: (app, command, parameters) ->
    localUser = app.localUsers[0]
    params = [ "-T", "-l", "u#{localUser.id }", localUser.machine.hostname, command ]
    for param in parameters.slice(0)
      params.push param
    @here "/usr/bin/ssh", params
  app: (id, command, parameters, callback) ->
    @applications (applications) =>
      application = (applications.filter (application) -> application.id is id).shift()
      localUser = application.localUsers[0]
      params = [ "-T", "-l", "u#{localUser.id }", localUser.machine.hostname, command ]
      for param in parameters.slice(0)
        params.push param
      program = spawn "/usr/bin/ssh", params
      stdout = ""
      stderr = ""
      program.stdout.on "data", (chunk) -> stdout += chunk.toString()
      program.stderr.on "data", (chunk) -> stderr += chunk.toString()
      program.on "exit", (code) ->
        if code is 0
          callback()
        else
          process.stderr.write "Cannot execute #{command}."
  delegate: (command, parameters) ->
    if require("./location").server
      command = @hereas "delegate", @command @parameters
      command.passthrough()
    else
      @application @options.app, (app) =>
        @abend "No such application #{@options.app}.\n" unless app
        command = @thereas app, "delegate", command, parameters
        command.passthrough()

module.exports.Configuration = Configuration
