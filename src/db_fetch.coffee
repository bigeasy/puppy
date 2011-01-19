require.paths.unshift("/puppy/lib/node")

exec            = require("child_process").exec
fs              = require "fs"
crypto          = require "crypto"
syslog          = new (require("common/syslog").Syslog)({ tag: "db_fetch", pid: true })
shell           = new (require("common/shell").Shell)(syslog)
db              = require("common/database")
{OptionParser}  = require("coffee-script/optparse")

argv            = process.argv.slice 2

console.log     argv

parser = new OptionParser [
  [ "-n", "--name [NAME]", "database name" ]
  [ "-e", "--engine [mysql/mongodb]", "database engine" ]
  [ "-a", "--app [NAME]", "application name" ]
]

usage = ->
  process.stdout.write parser.help()
  process.exit 1

try
  options         = parser.parse argv
catch e
  usage()

options.engine or= "mysql"
options.name or= options.engine

db.createDatabase syslog, (database) ->
  shell.hostname (hostname) ->
    if not /^\d+$/.test(options.app)
      id = /^t(\d+)$/.exec(options.app)
      if not id
        usage()
      options.app = id[1]
    hash = crypto.createHash "md5"
    urandom = fs.createReadStream "/dev/urandom", { start: 0, end: 4091 }
    urandom.on "data", (chunk) -> hash.update chunk
    urandom.on "end", ->
      database.select "insertDataStore", [ options.app, options.name, hash.digest("hex"), options.engine ], (results) ->
        dataStoreId = results.insertId
        shell.enqueue hostname,
          [ "mysql:create", [ dataStoreId ] ],
          [ "mysql:grant", [ options.app, dataStoreId ] ]
        process.stdout.write "Database d#{dataStoreId} for application t#{options.app} created.\n"
