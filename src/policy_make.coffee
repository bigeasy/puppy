require.paths.unshift("/puppy/lib/node")

require("common/shell").medo("/puppy/sbin/policy_make", process.argv.slice(2))
