require.paths.unshift("/puppy/lib/node")

require("common/shell").medo("/puppy/sbin/user_invite", process.argv.slice(2))
