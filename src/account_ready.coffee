require.paths.unshift("/puppy/lib/node")

require("common/shell").medo("/puppy/sbin/account_ready", process.argv.slice(2))
