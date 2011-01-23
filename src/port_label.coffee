require.paths.unshift("/puppy/lib/node")

require("common/shell").sudo("/puppy/sbin/port_label", process.argv.slice(2))
