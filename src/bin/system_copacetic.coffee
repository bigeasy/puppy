fs = require "fs"
syslog = new (require("common/syslog").Syslog)({ tag: "system_copacetic", pid: true })

module.exports.command = (argv) ->
  localUserId = parseInt(argv.shift(), 10)
  passwd = fs.readFileSync("/etc/passwd", "utf8")
  for directory in fs.readdirSync("/home")
    user = /^#{directory}:[^:]+:(\d+)/m.exec(passwd)
    if not user
      syslog.send("local5", "crit", "User directory #{directory} has no user.")
    else if /^u#{user[1]}$/.test(directory)
      stat = fs.statSync("/home/#{directory}")
      if stat.uid isnt parseInt(user[1], 10)
        syslog.send("local5", "crit", "Invalid home directory uid #{stat.uid} for user #{directory}.")
      if stat.gid isnt 707
        syslog.send("local7", "crit", "Invalid home directory gid #{stat.gid} for user #{directory}.")
      if (stat.mode & 0777) isnt 0700
        syslog.send("local5", "crit", "Invalid home directory mode #{stat.mode & 0777} for user #{directory}.")
        fs.chmodSync("/home/#{directory}", 0700)
    else if not /^alan|puppy|stunnel|vhosts$/.test(directory)
      console.log directory
      syslog.send("local5", "crit", "Unexpected user #{directory}.")
