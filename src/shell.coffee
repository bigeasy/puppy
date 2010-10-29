{spawn, exec} = require "child_process"

class Shell
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

module.exports.Shell = Shell
