{spawn, exec} = require "child_process"
sys = require "sys"

class Shell
  constructor: (@syslog) ->
  # Worker user do.
  medo: (splat...) ->
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
  doas: (user, command, parameters, input, callback) ->
    prefix = [ "-u", user, command ]
    while prefix.length
      parameters.unshift(prefix.pop())
    sudo = spawn "/usr/bin/sudo", parameters
    if input?
      sudo.stdin.write(input)
      sudo.stdin.end()
    stdout = ""
    stderr = ""
    sudo.stdout.on "data", (data) -> stdout += data.toString()
    sudo.stderr.on "data", (data) -> stderr += data.toString()
    sudo.on "exit", (code) =>
      if code
        @syslog.send "err", "Command #{command} exited with code #{code}.", { code, stdout, stderr }
        process.exit code
      callback(stdout)
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
  verify: (condition, message, context) ->
    unless condition
      context or= {}
      @abend message, context
  abend: (message, context) ->
    @syslog.send "err", "ERROR: #{message}", context
    process.exit 1
  hostname: (callback) ->
    hostname = spawn "/bin/hostname"
    stdout = ""
    stderr = ""
    hostname.stderr.on "data", (data) -> stderr += data.toString()
    hostname.stdout.on "data", (data) -> stdout += data.toString()
    hostname.on "exit", (code) =>
      if code != 0
        @abend "Unable to execute hostname.", { code, stderr, stdout }
      callback(stdout.substring(0, stdout.length - 1))
  enqueue: (hostname, splat...) ->
    commands = []
    for command in splat
      commands.push JSON.stringify(command)
    callback = if typeof splat[splat.length - 1] is "function" then splat.pop() else ->
    @doas "enqueue", "/puppy/bin/enqueue", [ hostname ], commands.join("\n"), (stdout) ->
  stdin: (length, callback) ->
    body = ""
    stdin = process.openStdin()
    stdin.setEncoding('utf8')
    stdin.on "data", (chunk) ->
      body += chunk
      if body.length > length
        dump = JSON.stringify { stdin: body.substring(0, 512) }
        callback(new RangeError("ERROR: Standard input longer than #{length} characters. #{dump}"), null)
        stdin.close()
    stdin.on "end", ->
      if body.length <= length
        callback(null, body)

module.exports.Shell = Shell
module.exports.sudo = (splat...)->
  shell = new Shell()
  shell.sudo.apply shell, splat
module.exports.doas = (splat...)->
  shell = new Shell()
  shell.doas.apply shell, splat
