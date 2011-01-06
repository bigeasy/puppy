require.paths.unshift("/puppy/lib/node")

require("common/shell").sudo("/puppy/sbin/user_decommission", process.argv.slice(2))
