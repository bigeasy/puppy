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
        env =
          NODE_PATH: "/opt/lib/node"
        child = spawn "/opt/share/puppy/private/bin/#{program.replace(/:/, "_")}", args, { env }
        child.stdin.write(input) if input
        child.stdin.end()
        stdout = ""
        stderr = ""
        child.stdout.on "data", (chunk) -> stdout += chunk.toString()
        child.stderr.on "data", (chunk) -> stderr += chunk.toString()
        child.on "exit", (code) ->
          program += " #{args.join(", ")}" if args.length
          if code
            syslog.send "err", stdout if /^ERROR:/.test(stdout)
            commands.length = 0
          stderr = stderr.substring(0, 1024)
          stdout = stdout.substring(0, 256)
          syslog.send "info", "Worker ran [#{program}] with exit code #{code}.", { command, stderr, stdout }
          task()
      else
        fs.unlinkSync job.name
        nextPoll()
    task()
  else
    nextPoll()

module.exports.poll = poll
