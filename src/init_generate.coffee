require.paths.unshift("/puppy/lib/node")

require("common/shell").sudo("/puppy/sbin/init_generate", process.argv.slice(2))
