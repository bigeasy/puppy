module.exports.command = (bin, argv) ->
  match = /^(\/home\/[^\/]+\/)/.exec(bin)
  process.exit 1 if not match
  require.paths.unshift "#{match[0]}/.node_libraries"
  [ noun, verb ] = argv.shift().split(/:/)
  require("../lib/#{noun}_#{verb}").command(bin, argv)
