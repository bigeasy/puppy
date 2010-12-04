{spawn, exec} = require "child_process"
sys = require "sys"

class Shell
  # Worker user do.
  wudo: (splat...) ->
    parameters = []
    for parameter in splat
      if parameter.join
        for param in parameter
          parameters.push param
      else
        parameters.push parameter
    command = parameters.shift()
    sudo = spawn command, parameters
    sys.pump process.openStdin(), sudo.stdin
    stderr = ""
    stdout = ""
    sudo.stderr.on "data", (data) -> stderr += data.toString()
    sudo.stdout.on "data", (data) -> stdout += data.toString()
    sudo.on "exit", (code) ->
      process.stdout.write JSON.stringify { stdout, stderr }
      process.exit code
  sudo: (splat...) ->
    parameters = []
    for parameter in splat
      if parameter.join
        for param in parameter
          parameters.push param
      else
        parameters.push parameter
    sudo = spawn "/usr/bin/sudo", parameters
    sys.pump process.openStdin(), sudo.stdin
    stderr = ""
    stdout = ""
    sudo.stderr.on "data", (data) -> stderr += data.toString()
    sudo.stdout.on "data", (data) -> stdout += data.toString()
    sudo.on "exit", (code) ->
      process.stdout.write JSON.stringify { stdout, stderr }
      process.exit code
  script: (splat...) ->
    callback = splat.pop()
    source = splat.pop()
    splat = [ splat[0], splat.splice(1) ]
    program = spawn.apply null, splat
    stderr = ""
    stdout = ""
    program.stderr.on "data", (data) -> stderr += data.toString()
    program.stdout.on "data", (data) -> stdout += data.toString()
    program.on "exit", (code) -> callback(code, stdout, stderr)
    program.stdin.write(source)
    program.stdin.end()
  enqueue: (hostname, splat...) ->
    console.log "ENQUEUE"
    callback = if typeof splat[splat.length - 1] is "function" then splat.pop() else ->
    ssh = spawn "/usr/bin/ssh", [ "-i", "/home/puppy/.ssh/id_puppy_private", "puppy@#{hostname}", "/opt/bin/enqueue" ]
    ssh.stderr.on "data", (data) -> process.stdout.write data.toString()
    ssh.stdout.on "data", (data) -> process.stdout.write data.toString()
    ssh.on "exit", (code) -> callback(code)
    for command in splat
      program.stdin.write(JSON.stringify(command) + "\n")
    program.stdin.end()
  stdin: (length, callback) ->
    body = ""
    stdin = process.openStdin()
    stdin.setEncoding('utf8')
    stdin.on "data", (chunk) ->
      body += chunk
      if body.length > length
        dump = JSON.stringify
          stdin: body.substring(0, 512)
        callback(new RangeError("ERROR: Standard input longer than #{length} characters. #{dump}"), null)
        stdin.close()
    stdin.on "end", ->
      if body.length <= length
        callback(null, body)

module.exports.Shell = Shell
module.exports.sudo = (splat...)->
  shell = new Shell()
  shell.sudo.apply shell, splat
module.exports.wudo = (splat...)->
  shell = new Shell()
  shell.wudo.apply shell, splat
