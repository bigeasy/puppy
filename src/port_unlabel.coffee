require.paths.unshift("/puppy/lib/node")

require("common/shell").sudo("/puppy/sbin/port_unlabel", process.argv.slice(2))
