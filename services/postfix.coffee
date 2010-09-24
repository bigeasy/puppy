# Probably easier to just write scripts, then.

{exec, spawn}   = require("child_process")
OptionParser    = require("coffee-script/optparse").OptionParser
fs              = require("fs")
sys             = require("sys")
stack           = require("../lib/stack")

configuration =
  email: "alan@blogometer.com"
  hostname: "piran.virtualbox"

SERVICE =
  install:  {}
  gmail:
    help:
      """
      Configure Postfix to use GMail as an email relay. Only appropriate for
      development servers.
      """
    switches: [
      [ '-u', '--user [USER]',          'GMail user name' ]
      [ '-p', '--password [PASSWORD]',  'GMail password' ]
      [ '-h', '--help',                 'Get help' ]
    ]
    secret: [ "password" ]
  blurdy:
    help: "BOOP"
  remove:   {}

BANNER =
"""
#{SERVICE[process.argv[0]]?.help || ""}

Usage: stack postfix:gmail 
"""

install = (callback) ->
  exec "dpkg --list | grep postfix > /dev/null", (error) ->
    if error
      env = process.env || {}
      env["DEBIAN_FRONTEND"] = "noninteractive"
      env["DEBCONF_FRONTEND"] = "noninteractive"
      exec "apt-get -y install postfix", env, (error, stdout) ->
        throw error if error
        callback()
    else
      callback()

switch process.argv.shift()
  when "install"
    install () ->
  when "printenv"
    env = process.env || {}
    env["DEBCONF_FRONTEND"] = "noninteractive"
    exec "printenv | sort", env, (err, stdout) ->
      throw err if err
      process.stdout.write stdout
  when "gmail"
    gmail = (user, password) ->
      console.log user + ", " + password

      # Add the GMail specific configuration to to master.cf file and write it.
      MASTER +=
      """
      587       inet  n       -       n       -       -       smtpd
          -o smtpd_sasl_auth_enable=yes
          -o smtpd_enforce_tls=yes
      """
      fs.writeFileSync("/etc/postfix/master.cf", MASTER + "\n", "utf8")

      # Add the GMail specific configuration to to main.cf file and write it.
      MAIN +=
      """
      relayhost = [smtp.gmail.com]:587
      smtp_sasl_auth_enable = yes
      smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
      smtp_sasl_security_options = noanonymous
      smtp_tls_CApath = /certs
      smtp_use_tls = yes
      transport_maps = hash:/etc/postfix/transport

      virtual_maps = hash:/etc/postfix/virtual_maps
      """
      fs.writeFileSync("/etc/postfix/main.cf", MAIN + "\n", "utf8")

      # Create the virutal maps file.
      fs.writeFileSync("/etc/postfix/virtual_maps",
      """
      root          #{configuration.email}
      postmaster    #{configuration.email}
      """ + "\n", "utf8")

      # Create the transport file.
      fs.writeFileSync("/etc/postfix/transport",
      """
      * smtp:[smtp.gmail.com]:587
      """ + "\n", "utf8")

      # Create the transport file after making sure no one can read it.
      fs.writeFileSync("/etc/postfix/sasl_passwd", "", "utf8")
      fs.chmodSync("/etc/postfix/sasl_passwd", 0600)
      fs.writeFileSync("/etc/postfix/sasl_passwd",
      """
      [smtp.gmail.com]:587 #{user}:#{password}
      """ + "\n", "utf8")

      # Correctly set the permissions of all but the other files.
      for file in "main.cf master.cf transport virtual_maps".split(" ")
        fs.chmodSync("/etc/postfix/#{file}", 0644)

      # Create the mailname file.
      fs.writeFileSync("/etc/mailname",
      """
      #{configuration.hostname}
      """ + "\n", "utf8")
      fs.chmodSync("/etc/mailname", 0644)

      # Run postmap on the database files.
      for file in "transport virtual_maps sasl_passwd".split(" ")
        stack.execute "/usr/sbin/postmap /etc/postfix/#{file}"

      if true
        stack.script "/bin/bash", """
        mkdir /var/spool/postfix/certs
        cp /etc/ssl/certs/*.pem /var/spool/postfix/certs
        c_rehash /var/spool/postfix/certs
        """, ->
          console.log "BAR"

    options = new OptionParser(SERVICE.gmail.switches, BANNER)
    o       = options.parse(process.argv)
    if not o.user
      console.log options.help()
      process.exit 1

    checkInstall = (user, password) ->
      install ->
        gmail user, password

    if not o.password
      stack.readSecret "Enter GMail password: ", (password) ->
        checkInstall o.user, password
    else
      checkInstall o.user, o.password

  when "remove"
    exec "apt-get -y purge postfix"
  else
    console.log SERVICE

MASTER =
"""
#
# Postfix master process configuration file.  For details on the format
# of the file, see the master(5) manual page (command: "man 5 master").
#
# Do not forget to execute "postfix reload" after editing this file.
#
# ==========================================================================
# service type  private unpriv  chroot  wakeup  maxproc command + args
#               (yes)   (yes)   (yes)   (never) (100)
# ==========================================================================
smtp      inet  n       -       -       -       -       smtpd
#submission inet n       -       -       -       -       smtpd
#  -o smtpd_tls_security_level=encrypt
#  -o smtpd_sasl_auth_enable=yes
#  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
#  -o milter_macro_daemon_name=ORIGINATING
#smtps     inet  n       -       -       -       -       smtpd
#  -o smtpd_tls_wrappermode=yes
#  -o smtpd_sasl_auth_enable=yes
#  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
#  -o milter_macro_daemon_name=ORIGINATING
#628       inet  n       -       -       -       -       qmqpd
pickup    fifo  n       -       -       60      1       pickup
cleanup   unix  n       -       -       -       0       cleanup
qmgr      fifo  n       -       n       300     1       qmgr
#qmgr     fifo  n       -       -       300     1       oqmgr
tlsmgr    unix  -       -       -       1000?   1       tlsmgr
rewrite   unix  -       -       -       -       -       trivial-rewrite
bounce    unix  -       -       -       -       0       bounce
defer     unix  -       -       -       -       0       bounce
trace     unix  -       -       -       -       0       bounce
verify    unix  -       -       -       -       1       verify
flush     unix  n       -       -       1000?   0       flush
proxymap  unix  -       -       n       -       -       proxymap
proxywrite unix -       -       n       -       1       proxymap
smtp      unix  -       -       -       -       -       smtp
# When relaying mail as backup MX, disable fallback_relay to avoid MX loops
relay     unix  -       -       -       -       -       smtp
	-o smtp_fallback_relay=
#       -o smtp_helo_timeout=5 -o smtp_connect_timeout=5
showq     unix  n       -       -       -       -       showq
error     unix  -       -       -       -       -       error
retry     unix  -       -       -       -       -       error
discard   unix  -       -       -       -       -       discard
local     unix  -       n       n       -       -       local
virtual   unix  -       n       n       -       -       virtual
lmtp      unix  -       -       -       -       -       lmtp
anvil     unix  -       -       -       -       1       anvil
scache    unix  -       -       -       -       1       scache
#
# ====================================================================
# Interfaces to non-Postfix software. Be sure to examine the manual
# pages of the non-Postfix software to find out what options it wants.
#
# Many of the following services use the Postfix pipe(8) delivery
# agent.  See the pipe(8) man page for information about ${recipient}
# and other message envelope options.
# ====================================================================
#
# maildrop. See the Postfix MAILDROP_README file for details.
# Also specify in main.cf: maildrop_destination_recipient_limit=1
#
maildrop  unix  -       n       n       -       -       pipe
  flags=DRhu user=vmail argv=/usr/bin/maildrop -d ${recipient}
#
# ====================================================================
#
# Recent Cyrus versions can use the existing "lmtp" master.cf entry.
#
# Specify in cyrus.conf:
#   lmtp    cmd="lmtpd -a" listen="localhost:lmtp" proto=tcp4
#
# Specify in main.cf one or more of the following:
#  mailbox_transport = lmtp:inet:localhost
#  virtual_transport = lmtp:inet:localhost
#
# ====================================================================
#
# Cyrus 2.1.5 (Amos Gouaux)
# Also specify in main.cf: cyrus_destination_recipient_limit=1
#
#cyrus     unix  -       n       n       -       -       pipe
#  user=cyrus argv=/cyrus/bin/deliver -e -r ${sender} -m ${extension} ${user}
#
# ====================================================================
# Old example of delivery via Cyrus.
#
#old-cyrus unix  -       n       n       -       -       pipe
#  flags=R user=cyrus argv=/cyrus/bin/deliver -e -m ${extension} ${user}
#
# ====================================================================
#
# See the Postfix UUCP_README file for configuration details.
#
uucp      unix  -       n       n       -       -       pipe
  flags=Fqhu user=uucp argv=uux -r -n -z -a$sender - $nexthop!rmail ($recipient)
#
# Other external delivery methods.
#
ifmail    unix  -       n       n       -       -       pipe
  flags=F user=ftn argv=/usr/lib/ifmail/ifmail -r $nexthop ($recipient)
bsmtp     unix  -       n       n       -       -       pipe
  flags=Fq. user=bsmtp argv=/usr/lib/bsmtp/bsmtp -t$nexthop -f$sender $recipient
scalemail-backend unix	-	n	n	-	2	pipe
  flags=R user=scalemail argv=/usr/lib/scalemail/bin/scalemail-store ${nexthop} ${user} ${extension}
mailman   unix  -       n       n       -       -       pipe
  flags=FR user=list argv=/usr/lib/mailman/bin/postfix-to-mailman.py
  ${nexthop} ${user}


"""

MAIN =
"""
# See /usr/share/postfix/main.cf.dist for a commented, more complete version


# Debian specific:  Specifying a file name will cause the first
# line of that file to be used as the name.  The Debian default
# is /etc/mailname.
#myorigin = /etc/mailname

smtpd_banner = $myhostname ESMTP $mail_name (Ubuntu)
biff = no

# appending .domain is the MUA's job.
append_dot_mydomain = no

# Uncomment the next line to generate "delayed mail" warnings
#delay_warning_time = 4h

readme_directory = no

# TLS parameters
smtpd_tls_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
smtpd_tls_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
smtpd_use_tls=yes
smtpd_tls_session_cache_database = btree:${data_directory}/smtpd_scache
smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache

# See /usr/share/doc/postfix/TLS_README.gz in the postfix-doc package for
# information on enabling SSL in the smtp client.

myhostname = #{configuration.hostname}
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
myorigin = /etc/mailname
mydestination = #{configuration.hostname}, localhost, localhost.localdomain, localhost
relayhost = 
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128
mailbox_size_limit = 0
recipient_delimiter = +
inet_interfaces = all

"""
