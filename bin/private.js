var path = require("path");
require.paths.unshift(path.dirname(process.argv[1]) + "/../lib/node");
require("../lib/command").command(process.argv.slice(2));