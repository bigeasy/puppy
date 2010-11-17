fs  = require "fs"

module.exports.command = (bin, argv) ->
  file = "/var/spool/puppy/#{process.pid}-#{new Date().getTime()}"
  stdin = process.openStdin()
  stdin.setEncoding "utf8"
  commands = []
  stdin.on "data", (chunk) -> commands.push chunk
  stdin.on "end", ->
    commands = commands.join ""
    console.log commands
    for line in commands.split /\n/
      continue if /^$/.test(line)
      console.log line
      process.exit 1 if not typeof JSON.parse(line) is "array"
    fs.writeFileSync "#{file}.tmp", commands, "utf8"
    fs.renameSync "#{file}.tmp", file
