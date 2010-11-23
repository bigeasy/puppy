syslog = new (require("common/syslog").Syslog)({ tag: "worker", pid: true })
spawn = require("child_process").spawn
fs = require "fs"

poll = ->
  jobs = []
  for job in fs.readdirSync "/var/spool/puppy"
    file = "/var/spool/puppy/#{job}"
    stat = fs.statSync file
    stat["name"] = file
    jobs.push(stat)

  # Sort the jobs by create date, oldest job first.
  jobs.sort (a, b) -> (new Date(a.ctime).getTime()) - (new Date(b.ctime).getTime())

  nextPoll = ->
    if jobs.length
      poll()
    else
      setTimeout poll, 1000

  # Perform the first job, if one exists.
  if job = jobs.shift()
    commands = []
    for command in fs.readFileSync(job.name, "utf8").split("\n")
      continue if /^\s*$/.test command
      commands.push(JSON.parse(command))
    task = ->
      if commands.length
        command = commands.shift()
        [ program, args, input ] = command
        child = spawn "/opt/share/puppy/private/bin/#{program.replace(/:/, "_")}", args
        child.stdin.write(input) if input
        child.stdin.end()
        child.stdout.on "data", (chunk) -> process.stdout.write chunk.toString()
        child.stderr.on "data", (chunk) -> process.stdout.write chunk.toString()
        child.on "exit", (code) ->
          program += " #{args.join(", ")}" if args.length
          syslog.send "info", "Worker ran [#{program}] with exit code #{code}.", { command }
          task()
      else
        fs.unlinkSync job.name
        nextPoll()
    task()
  else
    nextPoll()

module.exports.poll = poll
