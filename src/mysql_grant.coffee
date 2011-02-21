require.paths.unshift("/puppy/common/lib/node")

require("common/shell").sudo("/puppy/worker/sbin/mysql_grant", process.argv.slice(2))
