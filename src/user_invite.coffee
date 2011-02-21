require.paths.unshift("/puppy/common/lib/node")

require("common/shell").medo("/puppy/worker/sbin/user_invite", process.argv.slice(2))
