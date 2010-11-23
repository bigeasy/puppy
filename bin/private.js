var path = require("path");
require.paths.unshift(path.dirname(process.argv[1]) + "/../lib/node");
require("../lib/command").command(path.dirname(process.argv[1]), process.argv.slice(2));
