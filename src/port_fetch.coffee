module.exports.command = (argv) ->
  delegate = require("./puppy").delegate
  delegate("/puppy/bin/port_fetch", argv)
