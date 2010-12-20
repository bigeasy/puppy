# Require Node.js dependencies.
fs = require "fs"
spawn = require("child_process").spawn

# Require logging.
syslog = new (require("common/syslog").Syslog)({ tag: "worker", pid: true })

# Run this method every second to check for jobs to perform on a machine on
# behalf of the greater puppy ecosystem.
poll = ->
  # Stat all of the job files in the spool directory.
  jobs = []
  for job in fs.readdirSync "/var/spool/puppy"
    file = "/var/spool/puppy/#{job}"
    stat = fs.statSync file
    stat["name"] = file
    jobs.push(stat)

  # Sort the jobs by create date, oldest job first.
  jobs.sort (a, b) -> (new Date(a.ctime).getTime()) - (new Date(b.ctime).getTime())

  # We'll be performing this simple tests, to see if there are more jobs waiting
  # now or if we should take a quick nap before checking again. Note that,
  # calling poll again will read the directory again to bring in any new jobs
  # added while we were working.
  nextPoll = ->
    if jobs.length
      poll()
    else
      setTimeout poll, 1000

  # Perform the first job, if one exists.
  if job = jobs.shift()
    # A job file may contain multiple tasks, one on each line. We gather those
    # comamnds into an array, the recursively shift commands of the front off
    # the array and perform them until the job is complete.
    commands = []
    for command in fs.readFileSync(job.name, "utf8").split("\n")
      continue if /^\s*$/.test command
      commands.push(JSON.parse(command))
    # Run the next command or, because we've completed the job,  delete the job
    # file and poll for the next job.
    task = ->
      if commands.length
        # Commands are given as an array containing the program name, an array
        # of arguments to the program, and a string to feed to standard input.
        command = commands.shift()
        [ program, args, input ] = command
        env =
          NODE_PATH: "/opt/lib/node"
        child = spawn "/opt/share/puppy/private/bin/#{program.replace(/:/, "_")}", args, { env }
        child.stdin.write(input) if input
        child.stdin.end()

        # Children are supposed to write an error on stdout in the event of an
        # error and exit with a non-zero status in the event of an error. This
        # means that we can log the error result on behalf of the child process,
        # which makes scripting in `bash` easier. Easier `bash` means that I'm
        # more inclined to create many small programs.
        stdout = ""
        stderr = ""
        child.stdout.on "data", (chunk) -> stdout += chunk.toString()
        child.stderr.on "data", (chunk) -> stderr += chunk.toString()
        child.on "exit", (code) ->
          # Record the stderr messages, which we do not expect from the launch
          # program.
          if stderr
            syslog.send "err", "Worker recieved unexpected error messages from [#{program}] with exit code #{code}.", { command, stderr }
          outcome = null
          try
            outcome = JSON.parse(stdout)
          catch e
            syslog.send "err", "Worker recieved malformed stdout from [#{program}] with exit code #{code}.", { command, stdout }
          # Record the error if one was reported.
          if code
            syslog.send "err", outcome.stdout if outcome and /^ERROR:/.test(outcome.stdout)
            commands.length = 0

          outcome.command = command
          # Create a descriptive message for the logs.
          program += " #{args.join(", ")}" if args.length
          syslog.send "info", "Worker ran [#{program}] with exit code #{code}.", outcome

          # Execute the next task, if any.
          task()
      else
        fs.unlinkSync job.name
        nextPoll()
    task()
  else
    nextPoll()

syslog.send "info", "Initializing."
module.exports.poll = poll
