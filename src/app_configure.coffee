shell     = new (require("common/shell").Shell)()
database  = new (require("common/database").Database)()
fs        = require "fs"
syslog = new (require("common/syslog").Syslog)({ tag: "haproxy_configuration", pid: true })

module.exports.command = (bin, argv) ->
