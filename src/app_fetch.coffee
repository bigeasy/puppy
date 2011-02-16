module.exports.command =
  description: "Create a new application."
  execute: (configuration) ->
    configuration.delegate "/puppy/bin/app_fetch", []
