require.paths.unshift("/puppy/common/lib/node")

require("common/shell").medo("/puppy/worker/sbin/policy_ready", process.argv.slice(2))
