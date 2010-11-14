syslog = new (require("common/syslog").Syslog)({ tag: "worker", pid: true })
spawn = require("child_process").spawn
fs = require "fs"

poll = ->
  jobs = []
  for job in fs.readdirSync "/var/lib/puppy/spool"
    file = "/var/lib/puppy/spool/#{job}"
    stat = fs.statSync file
    stat["name"] = file
    jobs.push(stat)
  jobs.sort (a, b) ->
    (new Date(a.ctime).getTime()) - (new Date(b.ctime).getTime())
  job = jobs.shift()
  if job
    args = JSON.parse(fs.readFileSync job.name, "utf8")
    child = spawn "/home/puppy/bin/private", args
    child.stdout.on "data", (chunk) -> process.stdout.write chunk.toString()
    child.stdout.on "data", (chunk) -> process.stdout.write chunk.toString()
    child.on "exit", (code) ->
      console.log arguments
      syslog.send("local2", "info", "Worker completed #{args.join(", ")} with exit code #{code}.")
      fs.unlinkSync job.name
      if jobs.length
        poll()
      else
        setTimeout poll, 1000
  else
    setTimeout poll, 1000

module.exports.poll = poll
