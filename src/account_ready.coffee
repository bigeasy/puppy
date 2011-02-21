format = require("./puppy").format

module.exports.command =
  description: "Check if account regsitration is complete."
  execute: (configuration) ->
    configuration.home true, (home) ->
      if home is "pending"
        process.exit 1
