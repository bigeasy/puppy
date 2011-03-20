#!/usr/bin/env node

require.paths.unshift("/puppy/common/lib/node");
var program = __filename.replace(/^.*\/(.*).coffee$/, "$1");
require("common").sudo("/puppy/worker/sbin/" + program, process.argv.slice(2));
