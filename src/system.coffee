# Require Node.js core libraries.
path            = require("path")

# Require CoffeeScript core libraries.
OptionParser    = require("coffee-script/optparse").OptionParser

# Require Node Stack library.
stack           = require("./stack")

BANNER = ""

module.exports.actions =
  bootstrap: {}
  hello: {}
  deploy: {}

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
      #{stack.bash.functions}

      stack_history "Updating apt cache."
      stack_try apt-get update

      installed=$(dpkg --list | awk '{ print $2 }' | grep '^python-software-properties$')
      if [ "x-$installed" != "x-python-software-properties" ]
      then
        stack_history "Installing python-software-properties to add Launchpad PPAs"
        stack_try apt-get install -y python-software-properties
      fi

      if [ ! -e /etc/apt/sources.list.d/bigeasy-node-stack-lucid.list ]
      then
        stack_history "Adding Node Stack Launchpad PPA."
        stack_try add-apt-repository ppa:bigeasy/node-stack
        stack_try apt-get update
      fi

      installed=$(dpkg --list | awk '{ print $2 }' | grep '^coffeescript$')
      if [ "x-$installed" != "x-coffeescript" ]
      then
        stack_history "Installing CoffeeScript."
        stack_try apt-get install -y coffeescript
      fi

      stack_history "Performing distribution upgrade."
      stack_try aptitude -y dist-upgrade

      if [ $(cat /etc/hostname) != "#{remote.host}" ]
      then
        stack_history "Setting hostname to #{remote.host}."
        stack_try echo "#{remote.host}" >> /etc/hostname
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
      stack_try mkdir -p /home/#{admin.name}/.ssh
      stack_try touch /home/#{admin.name}/.ssh/authorized_keys
      stack_try chmod 600 /home/#{admin.name}/.ssh/authorized_keys
      stack_try echo "#{admin.key}" > /home/#{admin.name}/.ssh/authorized_keys
      stack_try chown -R #{admin.name}:#{admin.group} /home/#{admin.name}

      stack_history "Creating /etc/sudoers."
      stack_try cat <<HERE > /etc/sudoers
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

      if [ -e /var/run/reboot-required ]
      then
        stack_history "Reboot required. Rebooting."
        stack_try /sbin/shutdown -r now
      fi
      """, (error, stdout, stderr) ->
        if error
          console.log error
          console.log stdout
          console.log stderr

    update()

  deploy: (local, remote) ->
    remote.sudo.script "bash", """
    #{stack.bash.functions}

    stack_history "Updating apt cache."
    stack_try apt-get update

    stack_check_reboot

    stack_install git-core

    if [ ! -d ~/git/stack ]
    then
      stack_history "Installing Node Stack."
      stack_try mkdir -p ~/git
      stack_try cd ~/git && git clone git://github.com/bigeasy/node-stack.git stack 2>&1 > /dev/null
    fi

    stack_install nginx

    stack_install ufw

    if sudo ufw status | grep inactive > /dev/null
    then
        stack_history "Enabling Uncomplicated Firewall."
        stack_try ufw allow ssh
        stack_try ufw --force enable
    fi

    if stack_missing gitosis
    then
        stack_history "Preconfiguring gitosis."
        stack_try find /var/cache/apt/archives -name \\\\*.deb -exec rm {} \\\\\\;
        stack_try apt-get install -y -d gitosis
        stack_try dpkg-preconfigure -fnoninteractive /var/cache/apt/archives/gitosis*.deb
        stack_try echo "gitosis gitosis/username string git" | debconf-set-selections 
        stack_try apt-get install gitosis
    fi

    stack_install mysql-server
    """, (error, stdout, stderr) ->
      if error
        console.log "Had error."

module.exports.Server = class Server
  boostrap: ->
    options = new OptionParser(SWITCHES, BANNER)
    o       = options.parse(process.argv)

  _deploy: (local) ->
    local.sudo.script "bash", """
    #{stack.bash.history}

    stack_history "Reboot required. Rebooting system."
    """
