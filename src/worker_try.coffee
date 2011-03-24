require.paths.unshift("/puppy/common/lib/node")

# Require Node.js dependencies.
spawn     = require("child_process").spawn

require("common/private").createSystem __filename, "hostname", (system, hostname) ->
  uid = process.getuid()
  syslog = system.syslog
  syslog.send "info", "Initializing."
  poll = ->
    system.sql "getNextJob", [ hostname ], "job", (jobs) ->
      # Perform the first job, if one exists.
      if job = jobs.shift()
        start = new Date()

        # Commands are given as an array containing the program name, an array
        # of arguments to the program, and a string to feed to standard input.
        command = JSON.parse(job.command)
        [ program, args, input ] = command
        child = spawn "/puppy/worker/bin/#{program.replace(/:/, "_")}", args
        child.stdin.write(input) if input

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
          # Record the error if one was reported.
          if code
            throw new Error system.err "Worker received error exit from [#{program}].", { uid, command, code, stderr, stdout }
          # Record the stderr messages, which we do not expect from the launch
          # program.
          if stderr
            throw new Error system.err "Worker received error messages from [#{program}].", { uid, command, code, stderr, stdout }

          # Create a descriptive message for the logs.
          end = new Date()

          outcome =
            duration: end.getTime() - start.getTime()
            command: command
            args: args
            input: input if input

          if outcome.duration < 60000
            timing = "#{outcome.duration / 1000} seconds"
          else
            timing = "#{Math.floor(outcome.duration / 60000)} minutes #{(outcome.duration % 60000) / 1000} seconds"

          syslog.send "info", "Worker ran [#{program}] with exit code #{code} in #{timing}.", outcome

          # Execute the next task, if any.
          system.sql "deleteJob", [ job.id ], (results) ->
            if not results.affectedRows
              syslog.send "err", "Unable to delete job.", { results, command, stdout }
              process.exit 1
            poll()
      else
        setTimeout poll, 1000
  poll()
