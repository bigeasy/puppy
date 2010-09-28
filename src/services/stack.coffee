# Require Node.js core libraries.
path            = require("path")

# Require CoffeeScript core libraries.
OptionParser    = require("coffee-script/optparse").OptionParser

# Require Node Stack library.
stack           = require("../utility")

BANNER = ""

module.exports.actions =
  bootstrap: {}
  hello: {}

module.exports.Client = class Client
  hello: (local, remote) ->
    local.sudo.script "bash", """
    whoami
    """, (error, stdout) ->
      console.log stdout

  bootstrap: (local, remote) ->
    configuration = new (stack.Configuration)()

    # Options for bootstrap.
    switches = [
      [ '-l', '--login [USER]',         'The bootstrap login name' ]
      [ '-h', '--help',                 'Get help' ]
    ]

    options = new OptionParser(switches, BANNER)
    o       = options.parse(process.argv)
    if o.login
      remote = new (stack.Remote)(remote.host, o.login)

    update = ->
      admin = configuration.data.administrator
      remote.sudo.script "bash", """
      #{stack.bash.history}

      stack_history "Updating apt cache."
      apt-get update

      installed=$(dpkg --list | awk '{ print $2 }' | grep '^python-software-properties$')
      if [ "x-$installed" != "x-python-software-properties" ]
      then
        stack_history "Installing python-software-properties to add Launchpad PPAs"
        apt-get install -y python-software-properties
      fi

      if [ ! -e /etc/apt/sources.list.d/bigeasy-node-stack-lucid.list ]
      then
        stack_history "Adding Node Stack Launchpad PPA."
        add-apt-repository ppa:bigeasy/node-stack
        apt-get update
      fi

      installed=$(dpkg --list | awk '{ print $2 }' | grep '^coffeescript$')
      if [ "x-$installed" != "x-coffeescript" ]
      then
        stack_history "Installing CoffeeScript."
        apt-get install -y coffeescript
      fi

      stack_history "Performing distribution upgrade."
      aptitude -y dist-upgrade

      if [ $(cat /etc/hostname) != "#{remote.host}" ]
      then
        stack_history "Setting hostname to #{remote.host}."
        echo "#{remote.host}" >> /etc/hostname
      fi

      if /usr/sbin/groupadd --gid #{admin.gid} #{admin.group}
      then
        stack_history "Adding group #{admin.group} with gid #{admin.gid}."
      fi

      if /usr/sbin/useradd --uid #{admin.uid} --gid #{admin.gid} --shell /bin/bash --groups sudo #{admin.name}
      then
        stack_history "Adding user #{admin.name} with uid #{admin.uid}."
      fi

      stack_history "Adding public key to keyring of user #{admin.name}."
      mkdir -p /home/#{admin.name}/.ssh
      touch /home/#{admin.name}/.ssh/authorized_keys
      chmod 600 /home/#{admin.name}/.ssh/authorized_keys
      echo "#{admin.key}" > /home/#{admin.name}/.ssh/authorized_keys
      chown -R #{admin.name}:#{admin.group} /home/#{admin.name}

      stack_history "Creating /etc/sudoers."
      cat <<HERE > /etc/sudoers
      # /etc/sudoers
      #
      # This file MUST be edited with the 'visudo' command as root.
      #
      # See the man page for details on how to write a sudoers file.
      #
      Cmnd_Alias RSYNC = /usr/bin/rsync

      Defaults    env_reset

      # Host alias specification

      # User alias specification

      # Cmnd alias specification

      # User privilege specification
      root    ALL=(ALL) ALL
      backup  ALL=NOPASSWD:RSYNC

      # Allow members of group sudo to execute any command after they have
      # provided their password
      # (Note that later entries override this, so you might need to move
      # it further down)
      %sudo ALL=NOPASSWD:ALL
      HERE
      """, (error, stdout, stderr) ->
        if error
          console.log error
          console.log stdout
          console.log stderr

    update()

    return

    # Start by installing coffeescript and upgrading the distribution.
    remote.sudo.script "bash", """
    add-apt-repository ppa:bigeasy/node-stack
    apt-get update
    apt-get install coffeescript
    apt-get upgrade
    """, checkReboot

    checkReboot = (error) ->
      throw error if error
      # Time to check to see if reboot is necessary.
      remote.sudo.exec "ls /var/run/reboot-required", (error) ->
        if error
          local.say """
          The remote system is now rebooting after a package update. Wait for the
          reboot to complete an then to complete the bootstrap run:

              stack stack:bootstrap #{process.argv.join(" ")}
          """

module.exports.Server = class Server
  boostrap: ->
    options = new OptionParser(SWITCHES, BANNER)
    o       = options.parse(process.argv)
