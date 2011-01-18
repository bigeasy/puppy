require.paths.unshift("/puppy/lib/node")

require("common/shell").sudo("/puppy/sbin/mysql_grant", process.argv.slice(2))
