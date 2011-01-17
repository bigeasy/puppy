module.exports.command = (argv) ->
  delegate = require("./puppy").delegate
  delegate("/puppy/bin/db_fetch", argv)
