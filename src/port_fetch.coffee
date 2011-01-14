module.exports.command = (argv) ->
  applicationId = argv.shift()

  delegate = require("./puppy").delegate
  delegate("/puppy/bin/port_fetch", applicationId)
