#### Node Stack
# Manage your own Node.js stack from your command line.

# Require Node.js core libraries.
fs              = require "fs"
sys             = require "sys"
{exec, spawn}   = require "child_process"
Script          = process.binding('evals').Script

##### command()
# Process a command line.

USAGE =
"""
Node Stack management utility.

Usage: stack service:command [arguments]
"""
# Called from the `stack` executable.

command = ->
  qualified = /^(.*):(.*)$/.exec(process.argv.shift() || "")
  if not qualified
    return 1
  else
    exec "which coffee", (error, stdout) ->
      coffee = /^(.*)\n$/.exec(stdout)[1]
      # Broken.
      services = __dirname + "/../services"
      fs.readdir services, (error, files) ->
        service = /^#{qualified[1]}.coffee$/
        for file in files
          if service.test(file)
            run(coffee, "#{services}/#{file}", qualified)
            return 1
        console.log """
                    Cannot find service #{qualified[1]}.
                    """

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
    console.log modes
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
