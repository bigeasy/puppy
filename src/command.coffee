module.exports.command = (argv) ->
  [ noun, verb ] = argv.shift().split(/:/)
  process.stdout.write("I'm here: #{noun}.\n")
  require("../lib/#{noun}_#{verb}").command(argv)
