crypto    = require "crypto"
shell     = new (require("puppy/shell").Shell)()
database  = new (require("puppy/database").Database)()

module.exports.command = (bin, argv) ->
  register = (email, sshKey) ->
    hash = crypto.createHash("md5")
    hash.update(email +  sshKey + (new Date().toString()) + process.pid)
    database.error = (error) ->
      if error.number is 1062
        if /'PRIMARY'/.test(error.message)
          register(email, sshKey)
        else if /'Activation_Email'/.test(error.message)
          process.stdout.write """
          The email address #{email} is already registered.\n
          """
      else
        throw error
    database.select "getActivationByEmail", [ email ], "activation", (results) ->
      console.log results
      if results.length
        activation = results.shift()
        if activation.activated
          process.stdout.write """
          The email address #{email} is already registered and activated.\n
          """
        else
          mail = require("mail").Mail(
            host: "smtp.gmail.com"
            port: 587
            username: "messages@prettyrobots.com"
            password: "c3b8e5fd1b31cb88f489500897e7380d"
          )
          message = mail.message(
            from: "alan@prettyrobots.com"
            to: [ email ]
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
      else
        process.stdout.write """
        The email address #{email} is not registered.\n
        """
  register argv[0], argv[1]
