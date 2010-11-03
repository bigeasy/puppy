path = require("path");

require("../lib/command").command(path.dirname(process.argv[1]), process.argv.slice(2));
