require.paths.unshift("/puppy/lib/node")

fs        = require "fs"
spawn     = require("child_process").spawn
syslog    = new (require("common/syslog").Syslog)({ tag: "account_activate", pid: true })
shell     = new (require("common/shell").Shell)(syslog)
db        = require("common/database")
{OptionParser}  = require("coffee-script/optparse")

argv      = process.argv.slice 2

parser = new OptionParser [
  [ "-n", "--name [NAME]", "database name" ]
  [ "-a", "--app [NAME]", "application name" ]
]

usage = ->
  process.stdout.write parser.help()
  process.exit 1

try
  options         = parser.parse argv
catch e
  usage()

uid = process.getuid()
shell.verify(uid > 10000, "Inexplicable uid #{uid}")

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
