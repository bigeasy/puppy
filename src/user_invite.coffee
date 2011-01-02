require.paths.unshift("/puppy/lib/node")

syslog    = new (require("common/syslog").Syslog)({ tag: "user_invite", pid: true })
shell     = new (require("common/shell").Shell)(syslog)

mail      = require "mail"

sendActivation = (activation) ->
  # Note that, if we don't provide the domain name, then the mail module will
  # execute `/bin/hostname`, which it is not allowed to do, and send will fail.
  mail = require("mail").Mail(
    host: "smtp.gmail.com"
    port: 587
    domain: "prettyrobots.com"
    username: "messages@prettyrobots.com"
    password: "c3b8e5fd1b31cb88f489500897e7380d"
  )
  message = mail.message(
    from: "alan@prettyrobots.com"
    to: [ activation.email ]
    subject: "Activate Your Account at Puppy"
  )
  message.body """
  Didn't expect this message? Very, very sorry. See below.
  
  Welcome to Puppy, intelligent hosting for your Node.js web
  applications, with puppy-like workflow.
  
  Activate Puppy with the following command.
  
  $ puppy account:activate #{activation.code}
  
  Didn't expect this message?
  
  Someone might be annoying you with our signup form. Using your
  email instead of their own. Please let us know that you did
  not expect this message by clicking this link.
  
  https://www.runpup.com/bogus/#{activation.code}
  
  We'll put a stop to it.
  """
  message.send (error) ->
    if error
      syslog.send "err", error.message
      throw error
    syslog.send "info", "Invitation sent to #{activation.email}."
    process.stdout.write("{}")

shell.stdin 33, (error, code) ->
  if error
    syslog.send "err", "ERROR: #{error.message}"
    process.exit 1
  shell.doas "delegate", "/puppy/bin/user_activation", [], code, (stdout) ->
    activation = JSON.parse(stdout)
    sendActivation(activation)
