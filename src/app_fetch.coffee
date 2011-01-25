module.exports.command = (argv) ->
  console.log "app"
  delegate = require("./puppy").delegate
  delegate("/puppy/bin/app_fetch", [])
