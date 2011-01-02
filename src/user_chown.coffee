require.paths.unshift("/puppy/lib/node")

require("common/shell").sudo("/puppy/sbin/user_chown", process.argv.slice(2))
