#!/usr/bin/env node

var spawn = require("child_process").spawn
var program = "/puppy/worker/sbin/" + __filename.replace(/^.*\/(.*).coffee$/, "$1");
var run = spawn(program, process.argv.slice(1), { customFds: [ 0, 1, 2 ] });
sudo.on("exit", function (code) { process.exit(code) });
