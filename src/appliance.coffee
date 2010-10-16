fs      = require "fs"
Client  = require("mysql").Client

command = ->
  file = process.argv.shift()

  if not file
    throw Error("No file given.")

module.exports.command = command
