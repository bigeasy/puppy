require.paths.unshift("/puppy/lib/node")

require("common/shell").medo("/puppy/sbin/policy_generate", process.argv.slice(2))
