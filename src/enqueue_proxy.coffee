require.paths.unshift("/puppy/lib/node")

# Require Puppy command execution and logging.
syslog  = new (require("common/syslog").Syslog)({ tag: "enqueue_proxy", pid: true })
shell   = new (require("common/shell").Shell)(syslog)

# This simple proxy maybe something that we can wrap up for reuse.
argv = process.argv.slice(2)
commands = []
stdin = process.openStdin()
stdin.setEncoding "utf8"
stdin.on "data", (chunk)-> commands.push chunk
stdin.on "end", ->
  shell.doas "worker", "/puppy/bin/job", [], commands.join(""), ->
