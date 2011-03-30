fs        = require "fs"
spawn     = require("child_process").spawn

require("common").createShell __filename, (shell) ->
  uid = process.getuid()
  if not uid > 10000
    throw new Error shell.err "Inexplicable uid #{uid}"

  fs.readFile "/home/u#{uid}/app/configuration.json", "utf8", (error, contents) ->
    throw error if error
    configuration = JSON.parse(contents)
    database = null
    for k, v of configuration.databases
      if v.engine is "mysql"
        database = v
        break
    mysql = spawn "/usr/bin/mysql", [
      "--defaults-file=/home/u#{uid}/.my.#{database.alias}.cnf", "-u", "u#{uid}", "-h", database.hostname, database.name
    ], { customFds: [ 0, 1, 2 ] }
    mysql.on "exit", (code) -> process.exit code
