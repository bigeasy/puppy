require.paths.unshift("/puppy/common/lib/node")

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
require("common").createSystem __filename, (system) ->
  argv = process.argv.slice(2)

  hostname = argv.shift()

  input = []
  enqueue = ->
    command = [ argv.shift(), argv ]
    command.push(input.join("")) if input.length
    system.enqueue hostname, [ command ]

  # A hyphen at the end of commands indicates that the enqueued command expects
  # standard input, so gather some to add to the queue.
  if argv[argv.length - 1] is "-"
    argv.pop()
    stdin = process.openStdin()
    stdin.setEncoding "utf8"
    stdin.on "data", (chunk) -> input.push chunk
    stdin.on "end", -> enqueue()
  else
    enqueue()
