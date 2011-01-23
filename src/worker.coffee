# Require Node.js dependencies.
fs        = require "fs"
spawn     = require("child_process").spawn

# Require logging.
syslog    = new (require("common/syslog").Syslog)({ tag: "worker", pid: true })
shell     = new (require("common/shell").Shell)(syslog)
db        = require("common/database")

argv      = process.argv.slice(2)
hostname  = argv.shift()

work = (database, hostname) ->
  poll = ->
    database.select "getNextJob", [ hostname ], "job", (jobs) ->
      # Perform the first job, if one exists.
      if job = jobs.shift()
        start = new Date()

        # Commands are given as an array containing the program name, an array
        # of arguments to the program, and a string to feed to standard input.
        command = JSON.parse(job.command)
        [ program, args, input ] = command
        child = spawn "/puppy/bin/#{program.replace(/:/, "_")}", args
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
            syslog.send "err", "Worker recieved unexpected error messages from [#{program}] with exit code #{code}.", { command, stdout, stderr }
            process.exit 1
          outcome = null
          try
            outcome = JSON.parse(stdout)
          catch e
            syslog.send "err", "Worker recieved malformed stdout from [#{program}] with exit code #{code}.", { command, stdout, stderr }
            process.exit 1
          # Record the error if one was reported.
          if code
            if outcome and /^ERROR:/.test(outcome.stdout)
              syslog.send "err", outcome.stdout
            else
              syslog.send "err", "Worker recieved unexpected error messages from [#{program}] with exit code #{code}.", { command, stdout, stderr, outcome }
            process.exit 1

          outcome.command = command
          # Create a descriptive message for the logs.
          program += " #{args.join(", ")}" if args.length
          end = new Date()
          outcome.duration = end.getTime() - start.getTime()
          if outcome.duration < 60000
            timing = "#{outcome.duration / 1000} seconds" 
          else
            timing = "#{Math.floor(outcome.duration / 60000)} minutes #{(outcome.duration % 60000) / 1000} seconds" 
          syslog.send "info", "Worker ran [#{program}] with exit code #{code} in #{timing}.", outcome

          # Execute the next task, if any.
          database.select "deleteJob", [ job.id ], (results) ->
            if not results.affectedRows
              syslog.send "err", "Unable to delete job.", { results, command, stdout }
              process.exit 1
            poll()
      else
        setTimeout poll, 1000
  poll()

syslog.send "info", "Initializing."
module.exports.work = ->
  db.createDatabase syslog, (database) ->
    # Run this method every second to check for jobs to perform on a machine on
    # behalf of the greater puppy ecosystem.
    shell.hostname (hostname) ->
      work(database, hostname)
