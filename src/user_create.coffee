shell     = new (require("puppy/shell").Shell)()
database  = new (require("puppy/database").Database)()
fs        = require "fs"
exec      = require("child_process").exec

module.exports.command = (argv) ->
  localUserId = parseInt(argv.shift(), 10)
  systemId = localUserId + 10000
  if not /^u#{systemId}:/m.test(fs.readFileSync("/etc/passwd", "utf8"))
    console.log "CREATING USER"
    shell.script "/bin/bash", "-e", """
    /usr/sbin/useradd --gid 707 --uid #{systemId} --home-dir /home/u#{systemId} u#{systemId}
    """, (error, stdout, stderr) =>
      if error != 0
        console.log error
        throw new Error("Cannot create user.")
      initializeUser(localUserId)
  else
    shell.script "/bin/bash", "-e", """
    /bin/rm -rf /home/u#{systemId}
    umask 077
    /bin/mkdir -p /home/u#{systemId}
    /bin/mkdir -p /home/u#{systemId}/.ssh
    /bin/mkdir -p /home/u#{systemId}/program
    /bin/mkdir -p /home/u#{systemId}/storage
    /bin/touch /home/u#{systemId}/.ssh/authorized_keys
    /bin/chown -R u#{systemId}:puppy /home/u#{systemId}
    /sbin/restorecon -R -v /home/u#{systemId}
    """, (error, stdout, stderr) ->
      if error != 0
        console.log error
        throw new Error("Cannot user directory.")
      exec "/bin/hostname", (error, stdout) ->
        if error
          console.log error
          throw new Error("Cannot get hostname.")
        hostname = stdout.substring(0, stdout.length - 1)
        database.select "getLocalUserAccount", [ hostname, localUserId ], "account", (results) ->
          account = results.shift()
          sshKeys = "#{account.sshKey}\n"
          fs.writeFileSync("/home/u#{systemId}/configuration.json", JSON.stringify({ "hostname", hostname }), "utf8")
          database.select "getActivationByLocalUser", [ hostname, localUserId ], "activation", (results) ->
            sshKeys += "#{results[0].sshKey}\n" if results.length
            fs.writeFileSync("/home/u#{systemId}/.ssh/authorized_keys", sshKeys, "utf8")
