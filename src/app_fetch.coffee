module.exports.command = (argv) ->
  delegate = require("./puppy").delegate
  delegate("/puppy/bin/app_fetch", [])
