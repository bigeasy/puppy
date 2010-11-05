mail = require "mail"

module.exports =
  sendActivation: (activation) ->
    mail = require("mail").Mail(
      host: "smtp.gmail.com"
      port: 587
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
      throw error if error
