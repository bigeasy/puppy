#!/usr/bin/env coffee

fs = require "fs"

# There has got to be a better way to read these logs, to read them actually
# line by line.
back = []
for line in fs.readFileSync("/var/log/audit/audit.log", "utf8").split /\n/
  # Keep three lines, because three lines together represent a single socketcall
  # event.
  back.shift() if back.length is 3
  back.push line

  # We're looking to see if anyone is attempting # to read /dev/log, so we're
  # looking for UNIX socket events.
  #
  # The saddr field is a hex dump of a structure, 220 characters long, 110 bytes
  # long, consisting of a short type identifier, little-endian, and 108
  # character path to the socket. The hex pattern for the local socket type is
  # `0100`, since AF_LOCAL is 1 and the short value is little-endian. We match
  # the hex pattern for AF_LOCAL, capture the string. Stuff after the
  # terminating `00` is garbage.
  if match = /^type=SOCKADDR\s+msg=audit\(([\d.]+):(\d+)\):\s+saddr=([0-9A-F]+)/.exec(line)
    if path = /^0100(.*?)00/.exec(match[3])
      path = path[1]
      length = path.length / 2
      buffer = new Buffer(length)
      for i in [0...length]
        offset = i * 2
        buffer[i] = parseInt path.substring(offset, offset + 2), 16
      converted = buffer.toString("utf8", 0, buffer.length)
      if converted is "/dev/log"
        process.stdout.write "#{back.join "\n"}\n"
