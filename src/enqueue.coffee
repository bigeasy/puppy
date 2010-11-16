fs  = require "fs"

module.exports.command = (bin, argv) ->
  file = "/var/spool/puppy/#{process.pid}-#{new Date().getTime()}"
  fs.writeFileSync "#{file}.tmp", JSON.stringify(argv), "utf8"
