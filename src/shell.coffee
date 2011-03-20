{spawn} = require "child_process"

class module.exports.t Shell
  constructor: (@syslog) ->
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
