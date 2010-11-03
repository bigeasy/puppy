module.exports.command = (argv) ->
  [noun, verb] = argv.shift().split(/:/)
  require("../lib/#{noun}_#{verb}").command(argv)
