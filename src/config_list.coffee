fs = require "fs"

module.exports.command = (argv) ->
  try
    configuration = JSON.parse(fs.readFileSync("#{process.env["HOME"]}/.puppy/configuration.json", "utf8"))
  catch e
    configuration = {}
  for property in "email server".split(/\s+/)
    if configuration[property]
      process.stdout.write "#{property}=#{configuration[property]}\n"
