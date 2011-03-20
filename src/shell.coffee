{spawn} = require "child_process"

class module.exports.Shell
  constructor: (@syslog) ->

  err: (message, context) ->
    tag = @syslog.tag.replace(/^(.*?)\[.*$/, "$1").replace(/^.*?_(.*)$/, "$1")
    if context
      json = JSON.stringify(context, null, 2).replace(/^(\s*\S.*)$/mg, "    $1")
      "#{tag}[#{process.pid}/#{process.getuid()}]: #{message}\n\n#{json}\n"
    else
      "#{tag}[#{process.pid}/#{process.getuid()}]: #{message}"
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
    stdin.on "end", ->
      if body.length <= length
        callback(null, body)
