module.exports.command = (bin, argv) ->
  [ noun, verb ] = argv.shift().split(/:/)
  require("../lib/#{noun}_#{verb}").command(bin, argv)
