require.paths.unshift("/puppy/lib/node")

require("common/shell").medo("/puppy/sbin/policy_load", process.argv.slice(2))
