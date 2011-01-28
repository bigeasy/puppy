{OptionParser}  = require("coffee-script/optparse")
{Configuration,invoke} = require("./puppy")
fs = require "fs"

parser = new OptionParser [
  [ "-n", "--name [NAME]", "database name" ]
  [ "-e", "--engine [mysql/mongodb]", "database engine" ]
  [ "-a", "--app [NAME]", "application name" ]
]

usage = ->
  process.stdout.write parser.help()
  process.exit 1

module.exports.command = (argv) ->
  try
    options         = parser.parse argv
  catch e
    usage()

  if /^\d+$/.test(options.app)
    options.app = parseInt options.app, 10
  else
    id = /^t(\d+)$/.exec(options.app)
    if not id
      usage()
    options.app = parseInt id[1], 10

  if require("./location").server
    console.log "Local execution of mysql:prompt is not implemented."
    process.exit 1
  else
    configuration = new Configuration()
    configuration.applications (applications) ->
      localUser = null
      for application in applications
        if application.id is options.app
          localUser = application.localUsers[0]
          break
      tty = false
      for fd in [0...2]
        if (fs.fstatSync(0).isCharacterDevice())
          tty = true
          break
      invoke("/usr/bin/ssh", [ (if tty then "-t" else "-T"), "-q", "-l", "u#{localUser.id}", localUser.machine.hostname, "/puppy/bin/mysql_prompt" ], argv)
