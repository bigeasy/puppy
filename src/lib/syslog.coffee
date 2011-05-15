dgram = require "dgram"
fs = require "fs"

FACILITIES = {}
for facility, i in"kern user mail daemon auth syslog lpr news uucp cron authpriv
                ftp local0 local1 local2 local3 local4 local5 local6 local7".split /\s+/
  FACILITIES[facility] = i

LEVEL = {}
for level, i in "emerg alert crit err warning notice info debug".split /\s+/
  LEVEL[level] = i

module.exports.Syslog = class Syslog
  constructor: (options) ->
    @tag = options.tag or ""
    if options.pid
      @tag += "[#{process.pid}]"
    if @tag
      @tag += ":"
    @facility = FACILITIES[options.facility or "local5"]
    @port = options.port or 514
    @host = options.host or "127.0.0.1"
    @maxMessageSize or= 32
    @socket = dgram.createSocket "unix_dgram"

  error: (message, dump) ->
    @send "err", "ERROR: #{message}", dump

  actualSend: (buffer, callback) ->
    @socket.send buffer, 0, buffer.length, "/dev/log", -> callback() if callback

  send: (level, message, dump, callback) ->
    message += " #{JSON.stringify(dump)}" if dump
    code = (LEVEL[level] or LEVEL["info"]) + (@facility * 8)
    buffer = new Buffer("<#{code}>#{@tag} #{message}")
    if buffer.length > @maxMessageSize * 1024
      @send "err", "Log message size #{buffer.length} is greater than default size #{@maxMessageSize}k.", null, =>
        @actualSend(buffer, callback)
    else
      @actualSend(buffer, callback)
