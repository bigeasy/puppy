path = require "path"
fs = require "fs"
spawn = require("child_process").spawn

module.exports.command = (argv) ->
  ssh = spawn "ssh", [ "-T" ]
