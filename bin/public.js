var path = require("path");
process.stdout.write("Successful.\n");
require.paths.unshift(path.dirname(process.argv[1]) + "/../lib/node");
require("../lib/command").command(process.argv.slice(2));
