var path = require("path");
require.paths.unshift(path.dirname(process.argv[1]) + "/../lib/node");
require("../lib/enqueue_proxy").command(process.argv.slice(2))
