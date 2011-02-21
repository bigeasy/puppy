require.paths.unshift("/puppy/common/lib/node")

require("common/shell").sudo("/puppy/worker/sbin/port_label", process.argv.slice(2))
