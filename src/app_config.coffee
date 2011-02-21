require.paths.unshift("/puppy/common/lib/node")

require("common/shell").medo("/puppy/worker/sbin/app_config", process.argv.slice(2))
