require.paths.unshift("/puppy/lib/node")

require("common/shell").medo("/puppy/sbin/app_config", process.argv.slice(2))
