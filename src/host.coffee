stack = require("../lib/stack")

module.exports.actions =
  list: {}
  add: {}

module.exports.Client = class Client
  list: ->
    configuration = new (stack.Configuration)()
    for host, definition of configuration.data.hosts
      console.log host

  add: ->
    configuration = new (stack.Configuration)()
    for host in process.argv
      configuration.data.hosts[host] = {}
    configuration.save()

module.exports.Server = class Server
