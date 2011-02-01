require.paths.unshift("/puppy/lib/node")

require("common/shell").sudo("/puppy/sbin/daemon_stop", process.argv.slice(2))
