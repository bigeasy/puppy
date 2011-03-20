#!/usr/bin/env node

var spawn = require("child_process").spawn
var program = "/puppy/worker/sbin/" + __filename.replace(/^.*\/(.*)$/, "$1");
spawn(program, process.argv.slice(1), { customFds: [ 0, 1, 2 ] }).on("exit", function (code) { process.exit(code) });
