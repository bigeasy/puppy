require.paths.unshift("/puppy/lib/node")

# Require Node.js core modules.
fs = require "fs"

# Require Puppy command execution and logging.
syslog  = new (require("common/syslog").Syslog)({ tag: "job", pid: true })
shell   = new (require("common/shell").Shell)(syslog)
db      = require("common/database")

# Need to set a limit to the size of the incoming buffer. It should never be
# more than a kilobyte, so at 4K and we need to report an attack.
#
# We could check against the database to see if someone has the ability to
# perform the command, based on the original uid requesting the command.
#
# When evil is sent to enqueue, we need to write the bad data, at least the
# first 4K of it, to a file where we can inspect it.
#
# Ideally, any request to the system would aduit the request through all of its
# transitions. Ideally, there would be a real model, which might be preferable
# to sifting through a morass of log files.
#
# The error level should trigger an audit by the system administrator.
argv = process.argv.slice(2)

hostname = argv.shift()

input = []
enqueue = ->
  db.createDatabase syslog, (database) ->
    command = [ argv.shift(), argv ]
    command.push(input.join("")) if input.length
    database.enqueue hostname, [ command ]
if argv[argv.length - 1] is "-"
  argv.pop()
  stdin = process.openStdin()
  stdin.setEncoding "utf8"
  stdin.on "data", (chunk) -> input.push chunk
  stdin.on "end", ->
    enqueue()
else
  enqueue()
