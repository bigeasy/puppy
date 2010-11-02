exec = require("child_process").exec

module.exports.command = (argv) ->
  exec "/usr/bin/stunnel /etc/stunnel/stunnel.conf", (error) ->
    if error
      console.log error
      throw new Error("Cannot start tunnel.")
