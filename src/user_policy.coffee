require.paths.unshift("/puppy/lib/node")

require("common/shell").sudo("/puppy/sbin/user_policy", process.argv.slice(2))
