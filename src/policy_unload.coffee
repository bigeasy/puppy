require.paths.unshift("/puppy/lib/node")

require("common/shell").sudo("/puppy/sbin/policy_unload", process.argv.slice(2))
