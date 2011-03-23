{spawn}               = require "child_process"
{helpers: {flatten}}  = require "coffee-script"

# Encapsulates a command to invoke using `spawn`.
class Command
  # Create a command with the given `command` and command `parameters`.
  constructor: (@shell, command, parameters, options) ->
    @command = [ command, parameters, options ]
    @command.pop() unless options?

  assert: (message, splat...) ->
    callback = splat.pop() if typeof splat[splat.length - 1] is "function"
    splat.push (outcome) =>
      if outcome.code or outcome.stderr.length
        throw new Error @shell.err message, outcome
      callback(outcome) if callback?
    @run.apply this, splat

  # Execute the command and assert a successful error code before invoking the
  # callback.
  run: (splat...) ->
    outcome = { command: @command.slice(0), stderr: "", stdout: "" }

    callback = splat.pop() if typeof splat[splat.length - 1] is "function"
    input = splat.pop()

    program = spawn.apply null, outcome.command
    if input?
      program.stdin.write input
      program.stdin.end()
    program.stdout.on "data", (chunk) -> outcome.stdout += chunk.toString()
    program.stderr.on "data", (chunk) -> outcome.stderr += chunk.toString()
    program.on "exit", (code) ->
      outcome.code = code
      callback(outcome) if callback?

  # Inherit the standard I/O handles of the parent process.
  passthrough: (callback) ->
    program = spawn @command, @parameters, { customFds: [ 0, 1, 2 ] }
    program.on "exit", (code) ->
      if callback
        callback(code)
      else
        process.exit code
 
class module.exports.Shell
  constructor: (@syslog) ->

  err: (message, context) ->
    tag = @syslog.tag.replace(/^(.*?)\[.*$/, "$1").replace(/^.*?_(.*)$/, "$1")
    if context
      json = JSON.stringify(context, null, 2).replace(/^(\s*\S.*)$/mg, "    $1")
      "#{tag}[#{process.pid}/#{process.getuid()}]: #{message}\n\n#{json}\n"
    else
      "#{tag}[#{process.pid}/#{process.getuid()}]: #{message}"

  command: (command, parameters...) ->
    options = parameters.pop() if typeof parameters[parameters.length - 1] is "function"
    new Command(this, command, flatten(parameters), options)

  doas: (user, command, parameters, input, callback) ->
    params = [ "-u", user, command ]
    for param in parameters
      params.push param

    sudo = spawn "/usr/bin/sudo", params

    sudo.stdin.write(input) if input?

    [ stdout, stderr ] = [ "", "" ]
    sudo.stdout.on "data", (data) -> stdout += data.toString()
    sudo.stderr.on "data", (data) -> stderr += data.toString()

    sudo.on "exit", (code) =>
      if code
        throw new Error @err "Command #{command} exited with code #{code}.", { code, stdout, stderr }
      callback(stdout)

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
    stdin.on "end", -> callback(null, body) if body.length <= length
