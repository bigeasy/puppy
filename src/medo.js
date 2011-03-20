#!/usr/bin/env node

require.paths.unshift("/puppy/common/lib/node");
var program = __filename.replace(/^.*\/(.*).coffee$/, "$1");
require("system").medo("/puppy/worker/sbin/" + program, process.argv.slice(2));
