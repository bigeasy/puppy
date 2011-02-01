require.paths.unshift("/puppy/lib/node")

require("common/shell").sudo("/puppy/sbin/daemon_start", process.argv.slice(2))
