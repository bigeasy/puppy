require.paths.unshift("/puppy/lib/node")

require("common/shell").sudo("/puppy/sbin/policy_load", process.argv.slice(2))
