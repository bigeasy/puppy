require.paths.unshift("/puppy/lib/node")

require("common/shell").medo("/puppy/sbin/user_provisioned", process.argv.slice(2))
