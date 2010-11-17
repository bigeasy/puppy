path = require("path");

require("../lib/enqueue").command(path.dirname(process.argv[1]), process.argv.slice(2));
