{spawn}                     = require "child_process"
{helpers: {flatten, last}}  = require "coffee-script"

# Encapsulates a command to invoke using `spawn`.
class Command
  # Create a command with the given `command` and command `parameters`.
  constructor: (@shell, command, parameters, options) ->
    @command = [ command, parameters, options ]
    @command.pop() unless options?

  assert: (message, splat...) ->
    callback = splat.pop() if typeof splat[splat.length - 1] is "function"
    splat.push (outcome) =>
      if outcome.code or outcome.stderr?
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
    if program.stdout?
      program.stdout.on "data", (chunk) -> outcome.stdout += chunk.toString()
    if program.stderr?
      program.stderr.on "data", (chunk) -> outcome.stderr += chunk.toString()
    program.on "exit", (code) ->
      outcome.code = code
      delete outcome.stdout unless outcome.stdout.length
      delete outcome.stderr unless outcome.stderr.length
      callback(outcome) if callback?

  # Inherit the standard I/O handles of the parent process.
  passthrough: (callback) ->
    program = spawn @command, @parameters, { customFds: [ 0, 1, 2 ] }
    program.on "exit", (code) ->
      if callback
        callback(code)
      else
        process.exit code

module.exports.Shell = class Shell
  constructor: (@syslog) ->

  err: (message, context) ->
    tag = @syslog.tag.replace(/^(.*?)\[.*$/, "$1").replace(/^.*?_(.*)$/, "$1")
    if context
      json = JSON.stringify(context, null, 2).replace(/^(\s*\S.*)$/mg, "    $1")
      "#{tag}[#{process.pid}/#{process.getuid()}]: #{message}\n\n#{json}\n"
    else
      "#{tag}[#{process.pid}/#{process.getuid()}]: #{message}"

  run: (command, splat...) ->
    o = splat[splat.length - 1]
    if o? and typeof o is "object" and not (o instanceof Array)
      options = splat.pop()
    new Command(this, command, flatten(splat), options)

  runAs: (user, command, splat...) ->
    @run.apply this, flatten([ "/usr/bin/sudo", [ "-u", user, command ], splat ])

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
    stdin = process.stdin
    stdin.resume()
    stdin.setEncoding('utf8')
    stdin.on "data", (chunk) ->
      body += chunk
      if body.length > length
        dump = JSON.stringify { stdin: body.substring(0, 512) }
        callback(new RangeError("ERROR: Standard input longer than #{length} characters. #{dump}"), null)
        stdin.close()
    stdin.on "end", -> callback(null, body) if body.length <= length
 
module.exports.createShell = (filename, callback) ->
  programName = filename.replace(/^.*\/(.*?)(?:_try)?$/, "$1")
  branchName = filename.replace(/^\/puppy\/([^\/]+).*$/, "$1")
  tag = if programName.indexOf(branchName) is 0 then programName else "#{branchName}_#{programName}"
  callback(new (Shell)(new (require("./syslog").Syslog)({ tag, pid: true })))
