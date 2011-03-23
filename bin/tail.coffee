#!/usr/bin/env coffee
{OptionParser}  = require "coffee-script/lib/optparse"
{tz} = require "timezone"
{inspect} = require "util"
{merge} = require("coffee-script").helpers

fs = require "fs"

months =
  Jan: 0
  Feb: 1
  Mar: 2
  Apr: 3
  May: 4
  Jun: 5
  Jul: 6
  Aug: 7
  Sep: 8
  Oct: 9
  Nov: 10
  Dec: 11

createDate = (year, month, date, hours, minutes, seconds) ->
  new Date(year, month, date, hours, minutes, seconds)

parser = new OptionParser [
  [ "-n", "--lines [COUNT]", "number of lines to display" ]
  [ "-o", "--output [FORMAT]", "number of lines to display" ]
]

try
  options = parser.parse process.argv.slice(2)
catch e
  options.help()

options.lines or= 4
options.output or= "text"

readExceptions = (stderr, exceptions) ->
  # Split stderr into lines and pop the last blank line.
  stderr = stderr.split("\n")
  stderr.pop()

  # Read the stack backwards popping the all the stack lines and the blank line
  # before the stack.
  stack = []
  while stderr.length and
    ((match = /^\s{4}at\s(\S+)\s+\(([^:]+):(\d+):(\d+)\)$/.exec(stderr[stderr.length - 1]) or
        (match = /^\s{4}at(.*)\s([^:]+):(\d+):(\d+)$/.exec(stderr[stderr.length - 1]))))
    [ method, file, line, column ] = match.slice(1)
    stack.unshift { method, file, line, column }
    stderr.pop()

  # If we have a stack, then we have an exception.
  if stack.length
    # Pull the location display off the top of the lines, if it exists.
    if stderr.length >= 4 and stderr[0] is "" and (location = /^(.*):(\d+)$/.exec(stderr[1])) and (column = /^(\s*)\^$/.exec(stderr[3]))
      snippet =
        file: location[1]
        text: stderr[2]
        line: parseInt(location[2], 10)
        column: column[1].length + 1
      stderr = stderr.slice(4)

    # Read any JSON output, if it exists.
    json = []
    if /^\s{4}}/.test(stderr[stderr.length - 2])
      while not /^\s{4}{$/.test(line = stderr.pop())
        json.unshift line
      json.unshift line
      json = json.join "\n"
      stderr.pop()

    exception = { stack }

    process = null
    # What remains is the exception message. 
    message = stderr.join "\n -> "
    if match = /^Error:\s([\w_]+)\[(\d+)\/(\d+)\]:\s(.*)$/.exec(message)
      [ program, pid, uid, body ] = match.slice(1)
      message = "Error: #{body}"
      process =
        pid: parseInt pid
        uid: parseInt uid
        program: program
    else
      exception.message = message

    # Build the exception record.
    exception = { message, stack }
    if json.length
      try
        exception.json = JSON.parse(json)
      catch e
        exception.json = json
        exception.jsonInvalid = true
    exception.location = snippet if snippet
    exception.process = process if process

    exceptions.push exception
    if exception.json and exception.json.stderr
      readExceptions(exception.json.stderr, exceptions)

readBuffer = (buffer, end, contents, output, callback) ->
  chunkSize = 1024 * 2
  offset = end - chunkSize
  if offset <= 0
    contents = buffer.toString("utf8", 0, end) + contents
  else
    contents = buffer.toString("utf8", offset, end) + contents
  lines = contents.split /\n/
  lines.pop()
  contents = contents.substring(0, lines[0].length + 1)
  lines.shift()
  while lines.length and output.length < options.lines
    line = lines.pop()
    match = /^(\w{3})\s+(\d{1,2})\s(\d{2}):(\d{2}):(\d{2})\s([-_\w\d]+)\s+(.*)$/.exec(line)
    if not match
      continue
    date = [ (new Date()).getFullYear(), months[match[1]] ]
    date[2..5] = (parseInt(match[i], 10) for i in [2..5])
    date = createDate.apply(null, date)
    [ host, rest ] = match[6..7]
    if match = /^((?:private|public|worker|janitor)[_\w]*)\[(\d+)\]:\s+(.*?)(\s+{.*)?$/.exec(rest)
      [ program, pid, message, json ] = match[1..4]
      record = { date, host, program, pid, message }
      if json
        try
          record.json = JSON.parse(json)
        catch e
          record.json = json
          record.jsonInvalid = true
        if record.json.stderr
          exceptions = []
          readExceptions(record.json.stderr, exceptions)
          record.exceptions = exceptions if exceptions.length > 0 

      output.unshift record
  if offset > 0 and output.length < options.lines
    readBuffer buffer, offset, contents, output, callback
  else
    callback()

readLog = (fd, buffer, contents, size, output, callback) ->
  if size is 0
    callback()
  else
    position = if buffer.length >= size then 0 else size - buffer.length
    fs.read fd, buffer, 0, buffer.length, position, (error, read) ->
      readBuffer buffer, read, contents, output, ->
        readLog fd, buffer, contents, size - read, output, callback

makeDashes = (prefix, suffix) ->
  dashes = new Array((78 - prefix.length) / 2).join(" -")
  if suffix?
    length = (dashes.length - suffix.length - 1)
    length-- if length % 2
    dashes = dashes.substring 0, length
    "#{prefix} -#{dashes} #{suffix}"
  else
    "#{prefix} -#{dashes}"

writeExceptions = (exceptions, message) ->
  exception = exceptions.shift()

  # Write the exception divider.
  if exception.process
    suffix = (-> "#{@program}[#{@pid}/#{@uid}]").apply(exception.process)
    process.stdout.write "\n  #{makeDashes(message, suffix)}\n"
  else
    process.stdout.write "\n  #{makeDashes(message)}\n"

  # Print the context message if one exists.
  if exception.location
    (->
      process.stdout.write "  #{@file}:#{@line}.\n"
      process.stdout.write "  #{@text}\n"
      process.stdout.write "  #{new Array(@column).join(" ")}^\n"
    ).apply(exception.location)
  
  # Print the actual message, indented.
  process.stdout.write "#{exception.message.replace(/^([^\S\n]*\S.*)$/mg, "  $1")}\n"

  # Print JSON if any exists. If there is stderr output, replace it with a message
  # to look for the output below.
  if exception.json
    if exceptions.length
      exception.json.stderr = "v-V-v Nested exception: See below. v-V-v"
    else if exception.json.stderr? and exception.json.stderr.length
      stderr = exception.json.stderr
      exception.json.stderr = "v-V-v See below. v-V-v"
    json = inspect(exception.json, false, 1000).replace(/^([^\S\n]*\S.*)$/mg, "    $1")
    process.stdout.write "#{json}\n"
  for element in exception.stack
    if element.method
      process.stdout.write "    at #{element.method} (#{element.file}:#{element.line}:#{element.column})\n"
    else
      process.stdout.write "    at #{element.file}:#{element.line}:#{element.column}\n"
  if exceptions.length
    writeExceptions(exceptions, "Nested exception")
  else if stderr
    process.stdout.write "\n  #{makeDashes("Output from stderr")}\n"
    process.stdout.write stderr.replace(/^([^\S\n]*\S.*)$/mg, "  $1")

# In case you forget, you put this in its own method to get an empty namespace.
sendOutput = (output) ->
  switch options.output
    when "raw", "json"
      process.stdout.write JSON.stringify(output, null, 2)
      process.stdout.write "\n"
    else
      separator = ""
      for record in output
        process.stdout.write separator
        separator = "\n"

        prefix = "#{tz("%Y/%m/%d %H:%M:%S", record.date)} on #{record.host}"
        suffix = "#{record.program}[#{record.pid}]"
        dashes = new Array(80 - (prefix.length + suffix.length + 1)).join("-")

        process.stdout.write "#{prefix} #{dashes} #{suffix}\n\n"
        process.stdout.write "#{record.message}\n"

        stderr = null
        if record.json
          if record.exceptions
            record.json.stderr = "v-V-v Uncaught exception: See below. v-V-v"
          else if record.json.stderr? and record.json.stderr.length
            stderr = record.json.stderr
            record.json.stderr = "v-V-v  See below. v-V-v"
          json = inspect(record.json, false, 1000).replace(/^([^\S\n]*\S.*)$/mg, "  $1")
          process.stdout.write "#{json}\n"

        if record.exceptions
          writeExceptions(record.exceptions, "Uncaught exception")
        else if stderr
          process.stdout.write "\n  #{makeDashes("Output from stderr")}\n"
          process.stdout.write stderr.replace(/^([^\S\n]*\S.*)$/mg, "  $1")

fs.open "/var/log/messages", "r", (error, fd) ->
  throw error if error
  buffer = new Buffer(1024 * 1024 * 64)
  fs.fstat fd, (error, stats) ->
    throw error if error
    contents = ""
    output = []
    readLog fd, buffer, "", stats.size, output, -> sendOutput(output)
