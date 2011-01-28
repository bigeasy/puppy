module.exports.command = (argv) ->
  require("./puppy").application("/puppy/bin/mysql_prompt", argv)
