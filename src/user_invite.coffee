require.paths.unshift("/puppy/lib/node")

require("common/shell").medo("/opt/bin/private", "user:invite", process.argv.slice(2))
