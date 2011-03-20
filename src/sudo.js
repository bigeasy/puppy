#!/usr/bin/env node

var spawn = require("child_process").spawn
var program = "/puppy/worker/sbin/" + __filename.replace(/^.*\/(.*)$/, "$1");
var parameters = process.argv.slice(2);
parameters.unshift(program);
var sudo = spawn("/usr/bin/sudo", parameters, { customFds: [ 0, 1, 2 ] });
sudo.on("exit", function (code) { process.exit(code) });
