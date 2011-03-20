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
    if match = /^(worker)\[(\d+)\]:\s+(.*?)(\s+{.*)?$/.exec(rest)
      [ program, pid, message, json ] = match[1..4]
      record = { date, host, program, pid, message }
      if json
        try
          record.json = JSON.parse(json)
        catch e
          record.json = json
          record.jsonInvalid = true
        if record.json.stderr
          stderr = record.json.stderr.split("\n")
          stderr.pop() if stderr[stderr.length - 1] is ""
          stack = []
          while stderr.length and match = /^\s{4}at\s(\S+)\s+\(([^:]+):(\d+):(\d+)\)$/.exec(stderr.pop())
            [ method, file, line, column ] = match.slice(1)
            stack.unshift { method, file, line, column }
          if stack.length
            # Pull the location display off the top.
            if stderr.length >= 4 and stderr[0] is "" and (location = /^(.*):(\d+)$/.exec(stderr[1])) and (column = /^(\s*)\^$/.exec(stderr[3]))
              snippet =
                file: location[1]
                text: stderr[2]
                line: parseInt(location[2], 10)
                column: column[1].length + 1
              stderr = stderr.slice(4)
            # Ready an JSON context output.
            json = []
            if /^\s{4}}/.test(stderr[stderr.length - 1])
              while not /^\s{4}{$/.test(line = stderr.pop())
                json.unshift line
              json.unshift line
              json = json.join "\n"
              stderr.pop()
            message = stderr.join "\n"
            record.exception = { message, stack }
            if json.length
              try
                record.exception.json = JSON.parse(json)
              catch e
                record.exception.json = json
                record.exception.jsonInvalid = true
            record.exception.location = snippet if snippet

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

fs.open "/var/log/messages", "r", (error, fd) ->
  throw error if error
  buffer = new Buffer(1024 * 1024 * 64)
  fs.fstat fd, (error, stats) ->
    throw error if error
    contents = ""
    output = []
    readLog fd, buffer, "", stats.size, output, ->
      switch options.output
        when "raw", "json"
          process.stdout.write JSON.stringify(output, null, 2)
          process.stdout.write "\n"
        else
          for record in output
            header = "#{tz("%Y/%m/%d %H:%M:%S", record.date)} on #{record.host} "
            header += new Array(80 - header.length).join("-")
            process.stdout.write "#{header}\n\n"
            process.stdout.write "#{record.message}\n\n"
            if record.json
              if record.exception
                record.json.stderr = "[Uncaught exception: See below.]"
              json = inspect(record.json, 1000).replace(/^(\s*\S.*)$/mg, "  $1")
              process.stdout.write "#{json}\n\n"
            if record.exception
              process.stdout.write "  Uncaught exception - - - - - - - - - - - - - - - - - - - - - - - - - - - - -\n\n"
              if record.exception.location
                location = record.exception.location
                process.stdout.write "  #{location.file}:#{location.line}.\n"
                process.stdout.write "  #{location.text}\n"
                process.stdout.write "  #{new Array(location.column).join(" ")}^\n"
              process.stdout.write "#{record.exception.message.replace(/^(\s*\S.*)$/mg, "  $1")}\n\n"
              if record.exception.json
                json = inspect(record.exception.json, 1000).replace(/^(\s*\S.*)$/mg, "    $1")
                process.stdout.write "#{json}\n\n"
              for element in record.exception.stack
                process.stdout.write "    at #{element.method} (#{element.file})\n"
              process.stdout.write "\n"
