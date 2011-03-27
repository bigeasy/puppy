shell     = new (require("common/shell").Shell)()
database  = new (require("common/database").Database)()
fs        = require "fs"
syslog = new (require("common/syslog").Syslog)({ tag: "haproxy_configuration", pid: true })

module.exports.command = (bin, argv) ->
  applicationId = argv.shift()
  syslog.send "local5", "info", "Configuring HAProxy for application. applicationId=#{applicationId}"
  database.select "getApplicationPorts", [ applicationId ], "port", (results) ->
    ports = {}
    for i in [0...3]
      ports[i] = []
    for port in results
      ports[port.service].push port
    createSELinuxPolicy(applicationId, ports)

createSELinuxPolicy = (applicationId, ports) ->
  shell.script "/bin/bash", "-e", """
  /bin/mkdir -p /var/lib/puppy/selinux/haproxy#{applicationId}
  /bin/touch /var/lib/puppy/selinux/haproxy#{applicationId}/haproxy#{applicationId}.if
  /bin/mkdir -p /var/lib/puppy/bin
  /bin/touch /var/lib/puppy/bin/haproxy#{applicationId}
  /bin/chmod 0755 /var/lib/puppy/bin/haproxy#{applicationId}
  """, (error, stdout, stderr) ->
    fs.writeFileSync "/var/lib/puppy/bin/haproxy#{applicationId}", """
    #!/bin/bash
    /usr/sbin/haproxy -D -f /etc/haproxy/haproxy#{applicationId}.cfg -p /var/run/haproxy#{applicationId}.pid 
    """, "utf8"
    fs.writeFileSync "/var/lib/puppy/selinux/haproxy#{applicationId}/haproxy#{applicationId}.fc", """
    # haproxy labeling policy
    # file: haproxy.fc
    /var/lib/puppy/bin/haproxy#{applicationId}  -- gen_context(system_u:object_r:haproxy#{applicationId}_exec_t, s0)
    /etc/haproxy/haproxy#{applicationId}\.cfg   -- gen_context(system_u:object_r:haproxy#{applicationId}_conf_t, s0)
    /var/run/haproxy#{applicationId}\.pid       -- gen_context(system_u:object_r:haproxy#{applicationId}_var_run_t, s0)
    /var/run/haproxy#{applicationId}\.sock(.*)  -- gen_context(system_u:object_r:haproxy#{applicationId}_var_run_t, s0)
    
    """, "utf8"
    fs.writeFileSync "/var/lib/puppy/selinux/haproxy#{applicationId}/haproxy#{applicationId}.te", """
    policy_module(haproxy#{applicationId},1.0.0)
    
    require {
      type haproxy_exec_t;
    }
    ########################################
    #
    # Declarations
    #
    
    type haproxy#{applicationId}_t;
    type haproxy#{applicationId}_exec_t;
    init_daemon_domain(haproxy#{applicationId}_t, haproxy#{applicationId}_exec_t)
    
    type haproxy#{applicationId}_var_run_t;
    files_pid_file(haproxy#{applicationId}_var_run_t)
    
    type haproxy#{applicationId}_conf_t;
    files_config_file(haproxy#{applicationId}_conf_t)
     
    exec_files_pattern(haproxy#{applicationId}_t, haproxy_exec_t, haproxy_exec_t)
    exec_files_pattern(haproxy#{applicationId}_t, haproxy#{applicationId}_exec_t, haproxy#{applicationId}_exec_t)
    #######################################
    #
    # Local policy
    #
    
    # Configuration files - read
    list_dirs_pattern(haproxy#{applicationId}_t, haproxy#{applicationId}_conf_t, haproxy#{applicationId}_conf_t)
    read_files_pattern(haproxy#{applicationId}_t, haproxy#{applicationId}_conf_t, haproxy#{applicationId}_conf_t)
    read_lnk_files_pattern(haproxy#{applicationId}_t, haproxy#{applicationId}_conf_t, haproxy#{applicationId}_conf_t)
    
    # PID and socket file - create, read, and write
    files_pid_filetrans(haproxy#{applicationId}_t, haproxy#{applicationId}_var_run_t, { file sock_file })
    allow haproxy#{applicationId}_t haproxy#{applicationId}_var_run_t:file manage_file_perms;
    allow haproxy#{applicationId}_t haproxy#{applicationId}_var_run_t:sock_file { create rename link setattr unlink };
    
    allow haproxy#{applicationId}_t self : tcp_socket create_stream_socket_perms;
    allow haproxy#{applicationId}_t self: udp_socket create_socket_perms;
    allow haproxy#{applicationId}_t self: capability { setgid setuid sys_chroot sys_resource kill };
    allow haproxy#{applicationId}_t self: process { setrlimit signal };
    
    logging_send_syslog_msg(haproxy#{applicationId}_t)
    
    # use shared libraries
    libs_use_ld_so(haproxy#{applicationId}_t)
    libs_use_shared_libs(haproxy#{applicationId}_t)
    
    # Read /etc/localtime:
    miscfiles_read_localization(haproxy#{applicationId}_t)
    # Read /etc/passwd and more.
    files_read_etc_files(haproxy#{applicationId}_t)
    
    # Read /etc/hosts and /etc/resolv.conf
    sysnet_read_config(haproxy#{applicationId}_t)

    kernel_read_sysctl(haproxy#{applicationId}_t)
    kernel_read_system_state(haproxy#{applicationId}_t)
     
    # RHEL5 specific:
    require {
      type unlabeled_t;
      type haproxy#{applicationId}_t;
      class packet send;
      class packet recv;
    }
    
    #allow haproxy#{applicationId}_t unlabeled_t:packet { send recv };
    corenet_tcp_sendrecv_generic_if(haproxy#{applicationId}_t)
    corenet_udp_sendrecv_generic_if(haproxy#{applicationId}_t)
    corenet_tcp_sendrecv_generic_node(haproxy#{applicationId}_t)
    corenet_udp_sendrecv_generic_node(haproxy#{applicationId}_t)
    corenet_tcp_bind_generic_node(haproxy#{applicationId}_t)
    corenet_udp_sendrecv_generic_node(haproxy#{applicationId}_t)
    corenet_tcp_sendrecv_all_ports(haproxy#{applicationId}_t)
    corenet_udp_sendrecv_all_ports(haproxy#{applicationId}_t)

    type haproxy#{applicationId}_port_t;
    corenet_port(haproxy#{applicationId}_port_t)

    allow haproxy#{applicationId}_t haproxy#{applicationId}_port_t:tcp_socket name_bind;
    
    """, "utf8"
    shell.script "/bin/bash", "-e", """
    /usr/sbin/semanage port -d -p tcp #{ports[1][0].port}
    """, (error, stdout, stderr) ->
      shell.script "/bin/bash", "-e", """
      cd /var/lib/puppy/selinux/haproxy#{applicationId}
      /usr/bin/make -f /usr/share/selinux/devel/Makefile
      /usr/sbin/semodule -i /var/lib/puppy/selinux/haproxy#{applicationId}/haproxy#{applicationId}.pp || true
      /usr/sbin/semanage port -a -t haproxy#{applicationId}_port_t -p tcp #{ports[1][0].port}
      /sbin/restorecon -R /etc/haproxy /var/lib/puppy
      """, (error, stdout, stderr) ->
        if error != 0
          console.log stdout
          console.log stderr
          throw new Error("Cannot create haproxy directories.")
        createHAProxyConfiguration(applicationId, ports)

createHAProxyConfiguration = (applicationId, ports) ->
  shell.script "/bin/bash", "-e", """
  /bin/mkdir -p /var/lib/haproxy#{applicationId}
  umask 077
  /bin/touch /etc/haproxy/haproxy#{applicationId}.cfg
  """, (error, stdout, stderr) ->
    if error != 0
      console.log error
      throw new Error("Cannot create haproxy directories.")
    fs.writeFileSync "/etc/haproxy/haproxy#{applicationId}.cfg", """
    global
      log         127.0.0.1 local2 
      chroot      /var/lib/haproxy#{applicationId}
      pidfile     /var/run/haproxy#{applicationId}.pid
      maxconn     4000
      user        haproxy
      group       haproxy
      daemon
      # turn on stats unix socket
      #stats socket /var/lib/haproxy/stats#{applicationId}
    defaults
      mode                    http
      log                     global
      option                  httplog
      option                  dontlognull
      option                  http-server-close
      option                  redispatch
      retries                 3
      timeout http-request    10s
      timeout queue           1m
      timeout connect         10s
      timeout client          1m
      timeout server          1m
      timeout http-keep-alive 10s
      timeout check           10s
      maxconn                 3000
    frontend  main
      bind                    #{ports[1][0].machine.ip}:#{ports[1][0].port}
      default_backend         node
    backend node
      balance     roundrobin
      server  	  node1 	    #{ports[2][0].machine.ip}:#{ports[2][0].port}
    """, "utf8"
    fs.writeFileSync "/etc/monit.d/haproxy#{applicationId}", """
    check process haproxy#{applicationId} with pidfile /var/run/haproxy#{applicationId}.pid
      start program = "/var/lib/puppy/bin/haproxy#{applicationId}"
      stop program = "/home/puppy/bin/private haproxy:stop #{applicationId}"
      if cpu > 60% for 2 cycles then alert
      if cpu > 80% for 5 cycles then restart
      if 90 restarts within 100 cycles then timeout
    """, "utf8"
    shell.script "/bin/bash", "-e", """
    /sbin/service monit restart
    /usr/bin/monit monitor haproxy#{applicationId}
    """, (error, stdout, stderr) ->
      if error != 0
        console.log error
        throw new Error("Cannot restart monit.")
