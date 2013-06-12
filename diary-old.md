Stuff from the Puppy file that I'm organizing.

## Theory

 * Puppy is unnable to succeed as commodity. It is a **premium service**.
 * Puppy cannot be a commodity, because a single programmer cannot support a
   commodity business. However, a single programmer can support a **boutique
   business**.
 * Puppy purchases from Amazon EC2 at commodity prices and sells a 
   refined product. The commodity costs are fixed and passed on to the customer.
   Amazon EC2 does the market research for us.
 * Puppy is always available and redundant. There is no cheap scratch space.
 * There is a premium for Puppy. **That premium makes me customer focused**.
   There has to be enough on the line to care about a customer. I do not want to
   seek a price point where I distain every customer request. A customer must
   have some value.
 * Using CoffeeScript, Linux and EC2 I can rapidly prototype a Heroku-like and
   scale at cost.

This effort is possible due to a change in the marketplace.

 * Evented I/O minimizes resource usage.
 * Linux as an environment for simplicity and commodity pricing.
 * SELinux for enhanced security and multi-tenant hosting, taking advantage of
   Linux control groups, in lieu of virtualization, to acquire flexible resource
   allocation (the finance of computing).
 * CoffeeScript as a language and Node.js as a platform for rapid development.

### Why premium?

It seems that, I'd be able to support myself with 100 customers paying $24.00 a
month, especially if I fire unruley customers. 100 happy customers, making few
requests, so that I'm able to focus on developing new code. At 200 customers,
I'd have enough reveue to hire someone from within the community to support
other users.

I do not want my break even to be 1,000 different people. I will fail. My break
even has to be under 200 people. At that point I can grow, maybe from within the
community.

## Community

Create a brotherhood of developers who create lean, mean applications.

Beauty.

 * Create visualizations.
 * Create an enviornment for collaboration.
 * Workflow.

### Brotherhood

Create a space using Node.js where people can create and share software that
they can resell. This is done through the openest means possible, so that there
is a whole new application ecosystem.

## Workflow

Puppy workflow is simplified, by a number of factors.

 * shell - A Puppy hosting environment is simply a shell account.
 * ssh - The only protocol exposed to developers is ssh.
 * rsync - None of the complexity of git.

## Debugging

http://www.zachleat.com/web/2007/04/18/javascript-code-coverage-tool-for-firebug/

A code coverage tool for Firebug.

## Architecture

Amazon EC2, SSH, PostgreSQL and HTML 5 for visualization.

### Offering

User pays per instance hour for a control group. There are development cluster
gorups and production control groups. If you use a development cluster group,
you are on an unstable system that is optimized for price, where you're database
will failover frequently, to test failovers, where your application may relocate
frequently, to test relocations. You can overbook your control group, assigning
more than one application to the control group, but you are not allowed to
complain about using a development instance in this way.

Maybe, you're not allowed to assign other domain names. Certianly, you can't do
SSL or similar. It might be a huge limit, or limit enough, to not allow domain
name assignment, CNAMEs, etc.

### SSH is the Only Protocol

Everything is a command executed by SSH.

A web interface would run locally as a user that has the correct ssh key and
served off of localhost. Otherwise, the only protocol is SSH.

At some point, I might deploy Munin (or clone it in CoffeeScript), and then
there will be a need to have other keys and specific policies.

### PostgreSQL

The system lives in PostgreSQL. The other prototcol is the PostgreSQL protocol,
in addition to SSH. The message queue in in PostgreSQL. 

PostgreSQL is made redundant and available using `pgpool`.

### MongoDB

The document based offering.

### GlusterFS

All home directories are protected with GlusterFS.

### Temporary Space

You're allowed a quota of 100 MB of temporary space. There may be some reason to
increase this, or to burst it. Naw, increase it. $0.25 a GB. Some unit price.

## Logging and Monitoring

Centralized logging is supposed to be important. Monitoring using something like
Munin, which I already use, but people are going to want it to be web based.

The http would actually be proxied from your local machine, so that all
communication is done through SSH. The new Munin SSH transform in Munin 2.0
makes Munin sane, finally. Configuring that custom protocol was a major
annoyance.

 * [RDDtool](http://www.mrtg.org/rrdtool/) - The storage format used by Munin.
 * [Waiting for Munin 2.0 - Keep more data with custom data retention
   plans](http://blog.pwkf.org/post/2010/08/Waiting-for-Munin-2.0-Keep-more-data-with-custom-data-retention-plans)
   ~ States that: "RRD is Munin's backbone."
 * [Waiting for Munin 2.0 - Native SSH
   transport](http://blog.pwkf.org/post/2010/07/Waiting-for-Munin-2.0-Native-SSH-transport)
   ~ Description of the Munin SSH transport.
 * [Munin](http://munin-monitoring.org/) - Munin website.

Using Munin to gather time series data, then you'll need some way to munge logs.

 * [Syslog
   Remote](http://www.chinalinuxpub.com/doc/www.siliconvalleyccie.com/linux-hn/logging.htm)
   ~ Probably in the man page.
 * [Remote Logging with SSH and Syslog-NG](http://www.deer-run.com/~hal/sysadmin/SSH-SyslogNG.html)
 * [Secure central log server with syslog-ng and
   SSH](http://blesseddlo.wordpress.com/2010/06/29/secure-central-log-server-with-syslog-ng-and-ssh/)
   ~ One of many ways to do this.

I'd like to set this up and see how much performance suffers.

Also, I'd like to be able to work through the blackbox logs I created for nginx,
that I'll havet to also create for haproxy.

Until now, I had imagined that I would put the logs into a MySQL database for
analysis, but that would add MySQL as a depenency and it is lot a little thing.

Using RDD tool might be better, depending on what it does.

Using these logs, I'd like to get out in front of my traffic and do things like
tar pit crazed robots or spammers.

Other people who are working at the same thing...

Ideally, you could look for spiders or spammers and create a trigger that tells
HAProxy to tar pit them, so you can express the logic in JavaScript.

Going to use rsyslogd and record complicated messages, writing out stringified
JSON and using that in the database.

HAProxy is a challenge. We're going to need to know the PID of haproxy process
so we can extract the HAProxy logs and then associate them with an applicaiton.

Feeling like getting everything into PostreSQL is the right way to go, instead
of mucking about with a great deal of pain regarding files, munging line by
line, it seems like we can create warehouses for different system information,
create different models for different applications, from the databases.

Also, struck by how agonizing exception handling is in Java. Log and die.

Note that with worker, tracing progress is easy, since there is only one thread.

With others, we could set an environemnt variable, maybe proxy pid and start
date in seconds since the epoch. This would allow grouping by request.

Users on a Fedora system, and most UNIX systems, are able to send messages to
the system log using `/dev/log` and a program like `/usr/bin/logger` or the
`syslog` function in `libc`. This means that a malicious user, which I know I'll
have sooner than later, can fill the drive with malicious syslog messages.
Without any other form of auditing, these messages are untraceable.

It took a long time to find a solution, but oddly, just as it occured to me, I
for some found confirmation of the idea when I searched for `/dev/log` in
Google. The article [Preventing Syslog Denial of Service
attacks](http://www.hackinglinuxexposed.com/articles/20030220.html) describes
how to protect `/dev/log` with DAC ownership.

The Fedora 13 SELinux policy has been patched to allow all of the user types to
write to the system log. It would be nice if this was tunable, but no. To have
the second level of protection, I'm going to have to copy `userdomain.if` and
change it to create puppy based policies. This might be done using a Perl
script that can maintain the source code. Then I can try basing my logins on the
stricter SELinux policies.

## Watching Node.js

That is the job of Monit. Not sure what to do if a process totally runs away,
Monit will stop monitoring.

 * [Linux Process
   management](http://www.comptechdoc.org/os/linux/howlinuxworks/linux_hlprocess.html)
 * [Introduction to Linux Process
   Management](http://www.2000trainers.com/linux/linux-process-manage/)

## Multi-Tenant

My work on Puppy was initially in Ubuntu. However, I read about how little
Ubuntu had contributed to the kernel while at the same time heard Buster
Poindexter speak about how important it is to get your code into the actual
kernel, if it is supposed to live in kernel space. Patches will always fall out
of sync and play catch up. Thus, initially I was looking at AppArmor, but
utlimately, I wanted to use SELinux.

SELinux makes Multi-Tenant possible. The nature of node also makes it possible.

How many users can a system have? Do I want multi-tenant, with user names, or
would I rather have some other way of auditing execution?

At first thought; Could I override exec and spawn to log calls, but then how to
analyze all that data? Ubuntu seems to be doing okay with thier Code of Conduct.
Maybe I can get people to sign something, so that at least I have a working
email address, or else maybe there is some way to submit for audit, here are the
commands that will be called.

Then I looked secure computing and found my way to SELinux. It might be a
solution to isolate a guest executable. The only need to go to the shell is to
run something like ImageMagick, or else shell out to something like Prawn. The
problems are greatly reduced if the application can be restricted by the kernel.

Finding out how the PHP hosting services approach security with Google searches
for "Securing Plesk" and "Securing cPanel". Examples such as
[How to Secure Plesk
Servers](http://www.webhostingtalk.com/showthread.php?t=590737)  show that they
do the basics, try to avoid handing out shell accounts.

### Application Launch

Currently, I'm looking at creating a profile for each person, but really I need
to have a common profile, associated with a group, and not %puppy, but a new
group, and then create a policy for each application.

Then I need one place where I can transition using an application, the same
application, called from upstart. That application in turn calls an application
in the home directory.

### Binding

A tenant would bind to a port provided. How to enforce this?

 * socat and have the app use a named pipe?
 * [netfilter](http://www.netfilter.org/projects/libnetfilter_queue/index.html)?

Or simply, the server binds to an ephemeral port. The application is served
through a single listener, sockets, https, http, the whole deal. After the
program launches, the laucher will take note of the pid, then see which pid has
an ephemeral port, then... 

And then, yes, create a bunch of UIDs and make sure that the correct UID has the
port. It will be hard to steal ports in this way.

[SELinux](http://selinuxproject.org/) does all of this. SELinux does the port
blocking. There is no easier way to do it. As bad a rap as SELinux gets, and it
might simply be the fact that it was first, SELinux will lock down this Node.js
environment of my imagining nicely.

 * [SELinux in main/restricted](https://lists.ubuntu.com/archives/ubuntu-hardened/2010-February/000510.html)

I'm trying to look at the AppArmor code. From their Roadmap it looks like it is
all C++ and that they are whole hog Modern C++ and looking for ways to adopt
more C++. While the selinux code is in the kernel under `security/selinux`.
Looking at the AppArmor code, it looks like plain C. Confusing.

AppArmor appears to want to up the ante with a lot more default checking of the
network and the like. It doesn't have port blocking. It is wrapped into Ubuntu
pretty tight. It is an Ubuntu project.

### Guest Accounts

Much easier to use guest accounts. There is a way for you to deploy your
applications into a guest account. The bundle unrolls your application into a
guest account.

### Single User Accounts

The guest accounts will be reusable. I'm trying to sort out where the data will
live, though. If I am giving them a little bit of file space, that they can use
to experiment with databases, or store files, serve static files, etc.

The could be allowed to generate html and serve static HTML using nginx for
simplicity and performance. There could be a notion of things being nginx rooted
or Node.js rooted. The current idea is to have nginx off to the side.

This single usage accounts have a market, but they do not allow for scale. That
needs to be communicated to the user. There is a place for it. You can create
silos for your customers, move your customers between silos, if your
architecture is that simple.

You could even allow nodes to speak to each other in the data center, to move
things around and balance yourself.

## Staging

Seems like you're going to want to offer staging and suchlike. Maybe verisoned
applications and APIs?

## Features

Here are features. (Ha! Ha! Is this your MVP?)

 * DNS - Need an appliance. Wild card domains no problem.
 * SSL - STunnel. Deploy your certificate and it goes.
 * Twitter - Ready to go twitter integration with a community database.
 * Facebook - Ready to go Facebook APIs.
 * Backups - Of files. Databases are somewhat secure. Hourly if you like.
 * Upload/download databases - Upload and download your databases, applies to
   your ordinary transfer. Need something like taps.
 * Logging - Analytics. See who's hitting your sites. Spiders too.
 * Balancing - Turn on balanacing and increase your uptime.
 * Rolling deployment - Optionally upgrade your application a server at a time
   so that the old service runs while the new service deploys.
 * MongoDB - As a bundle.
 * Process usage - Not your process usage.
 * Deploy hooks - fixup your files after deplyment.
 * Cron - No problem. Customize cron to run as frequently as you like. Your
   custom crontable will run Node.js programs in your bundle. Restrictions
   apply. Hmm... Maybe cron like? Something I can parse and ensure is only
   running programs in the local directory.
 * WebWorkers. No big deal. Same restrictions to node process apply. Maybe a
   WebWorker is simply a spawned program.
 * EMail.  Send via GMail. A recipe? Can I configure sendmail per user?
   SendGrid. Create a relay appliance.
 * Memcache. Curious. Probably not a big deal, structure like any ohter
   database.
 * SMS - Look at Moonshadow.
 * Full text search - Web solar maybe?

## Durability

Applications themselves are not necessarily durable, but the general
configuration can live across machines. Ultimately, we're going to build all
these files, like the users, through tempatles.

At this point though, users are guest00001 through guest99999 and are only used
to assign ports. The notion of preserving a configuration is not as important,
there will be very little to configure.

Basicallly, there is the Node.js hosting, which will have some files, but the
promises on those files are not going to be robust. They will be as durable as
the underlying hosting, maybe with nighly backups. If you need more than this,
you can use S3, which does this right.

Nightly backups may be appropriate for your application though. It might be that
the real data is living somewhere else, you're just caching it, etc.

Then you're going to have services, MongoDB, MySQL, PostreSQL, Redis. Thesea re
going to have their own backups strategies.

## Ports

Something like a local Fast CGI requires a port. What about running your own
little servers or background processes? Is that allowed?

## Applications

MVC is silly, but separating styles, that is useful, so people can contribute to
a common base, but protect their identity.

## Deployment

Cakefile, Rakefile or Makefile and the target is "node:deploy".

Structure

    home
      private
        environment
      static
      dynamic

I am probably not going to offer `git`, or if I do, it is not going to be
integral. In fact, I can probably offer checkout from Subversion, but no, there
is no need to support that sort of nonsense, people can use `rsync`. Actually,
yes, I want to offer version control when the user is developing through the web
interface, but we need tiers then. In any case, it is a hook that triggers the
rebuild. I don't know how to offer git hosting without being GitHub, so I'm
going to have to find a way to work with GitHub, or else only offer http, or
something. The notion of the online editing, that is strong, but I don't relish
building out an entire infrastructure. This is business. Git may or may not be
expensive to host, but there is a lot of development to get the nice
visualizations of the code. GitHub does that so well, but GitHub has no concept
of privacy. 

Need to ensure that their kit is complete. They must by running from a POSIX
environment, no support for Windows. (That will be the online editor versions,
web based sync, or some such, maybe DAV?)

Thought is this, there is always one account, and the user is used to that, you
must always have at least one account, or one application.

Applications are mapped to a user, and that is that.

Uploading to `~/.puppy/stage/date`. This might get queued up all wonky, two
different deploys at once, but that's okay for now, we can lock later, so that
events are atomic, hmm... lock with database? lock with file? No. Put a record
in the database and remove it when you are done, the record is indexed, so it
will puke if it is already there.

Then you need to move the stage to the different servers. Generate a key for
this. The key is generated with.

    ssh-keygen -N '' -t rsa -b 2048 -f /home/alan/blurgh

The file goes somewhere that is only read by janitor. The files are synced to
`~/.puppy/stage/date` on each server. When the syncing is done, the sync is made
from the stage to the application. First stop the server. Close sync. Start the
server.

When launching, first transition to a preparation script, which the the
transition script now. This will create the stdout directories, then sudo 

Debating as to whehter or not each utility should set the correct permissions,
since I want to run each utility, or rather, I want to run configuration and
know that configuration is correct, without having to go through the var tree.

It is easier to set the type context using restorecon than to build out a type
transition, and two layers of type transition in the launch, which means the
start script would create the directory, which we don't want to deal with,
because it can't, it won't run as root to create the directory at the DAC level.
You'd have to transition to a type context running as root to prepare, then
transition to a type context for running the daemon. I don't want to initialize
in startup. I want it to be ready when Upstart is called.

The three step deployment looks kind of flakey. Maybe we can upload to a
generated directory, then sync to that directory? No. Don't want to create
copies of applications. How about a lock, then track stages that can timeout.
This way, we can see where we died. If we die before the deployment, then we
simply reset, but know that there are no real problems.

## Upgrades

How do you move form one version of Node.js next?

Not that difficult really. Just put a version of node in its own directory.

You can launch any version of node. It's not going to cost any more or less to
run a new instance of a different version.

You can run on any version of node.

It seems simpiler to build from source, instead of installing a particular
version, to build from source.

## Security

 * [Snort](http://www.snort.org/).
 * [Chapter 19. Here Documents](http://tldp.org/LDP/abs/html/here-docs.html).
 * [Secure temporary files in Linux](http://blogs.techrepublic.com.com/opensource/?p=171).

## Client Accounts

The basic tasks are all performed by a one, two punch. First a file is created
with a task request. Then we use d

 * [Dangers of SUID Shell Scripts](http://www.forteach.net/os/sysadmin/35591.html)

## Static Resources

The URL structure of the application is part of the user inferace. The URL of
the static resources is not part of the user interface.

Thus, static resources are served off of the URL `/static` which is reserved for
static resources. 

My concern is that there will be a need to have it the other way round, where
the website is primarily static. I'm sure this will be the case, because this is
how I imagined I'd create an applicaiton, where the structure is split between
static pages, served as `*.html` and dynamic pages.

It may be the case that each application gets its own haproxy rules.

I'll know more about this, the more I know about haproxy.

There could be alternatives, you could serve a static site, 

One of there reasons I'm concerned about static resources is that I want to be
able to expire them quickly, so that you can serve static files, but update
them, and a browser refresh brings a new page. That is possible with static
pages, served from nginx. Can you get the same expiration from Varish?

## Code Editing

There are two contenders, [Code Mirror](http://codemirror.net/) and
[Bespin](https://bespin.mozillalabs.com/). The latter appears to be a bit much.
Kind of burried in Mozilla Labs, probably subject to the bike shed mentality.
There is no working demo and no examples of use. 

Code Mirror documentation is very glib:

 * Safari will not allow client scripts to capture control-z presses, but you
   can use control-backspace instead on that browser.
 * There is a function CodeMirror.isProbablySupported() that causes some
   1998-style browser detection to happen...

He is speaking to his inner troll. This is the code I will use.

 * [jsTree](http://www.jstree.com/) -

## Adoption Checklist

 * Is it on GitHub?
 * Can I see a demo?
 * Do I see any of these words, depricated, refactor, roadmap?


## Java, Virtualization, Cross-Platform

Windows is dead to me. It is a non-targeted operating system. It is not a
server. It is a device. It is less capable than an iPhone, but, maybe more
capable, than, say, oh, well I don't know.

Android is built on a nonsense technology, Java.

Thus, we're in the right groove. This Google Tech Talk by
[Greg Kroah Hartman](http://www.youtube.com/watch?v=L2SED6sewRw) about the
Kernel argues that something must be in the kernel to move fast, which is why
I'm moving to Fedora, away form Ubuntu. In this discussion, I learned more about
Ubuntu, which is created by a fellow named [Mark
Shuttleworth](http://www.markshuttleworth.com/archives/439), and does not put
back into the kernel what it takes out. I believe this accusation, which is
still being made this year, about
[GNOME](http://gregdekspeaks.wordpress.com/2010/07/29/red-hat-16-canonical-1/) . 

This puts me off AppArmor, but now, it appears that Ubuntu is [getting in into
the
kernel](http://www.ubuntu-user.com/Online/Blogs/Amber-Graner-You-in-Ubuntu/AppArmor-makes-it-into-the-2.6.36-Upstream-Kernel),
and yet, somehow it seems like, if that is their only contribution, it might be
a fig leaf of an offering, but, if it is in the kernel it is in the kernel.

 * [Ubuntu Empire Strikes
   Back](http://www.linuxjournal.com/content/ubuntu-empire-strikes-back)
 * [Open Source
   Numbers](http://www.theregister.co.uk/2010/08/13/open_source_numbers/)

But, SELinux is in the kernel now.

This exchange shows me that
[Shuttleworth](http://www.markshuttleworth.com/archives/77#comment-32120) is
huckster and very good at not giving answers.

But, he also talks about virtualization, and the focus is the release process,
there are no more stable versus development, it is all development, and he
believes that enterprise is nonsense, freezing a kernel is rediculous, because
then you have to patch it, which means doing en-masse what is done
incrementally, duplication of the efforts of many by an internal team, madness.
He then adds that the need for stability is easily attained through
virtualization. If someone needs Fedora Core 3 for their application, then can
easily put it on a machine that is above th latest kernel on the latest
hardware.

Which makes me hate Java all the more. The brilliance of that strategy, the
incredible non-goal of cross-platform Java. Must be a dying platform. It did not
win a place on the desktop, and now knowing your operating system, counting on a
virtual machine, it is all so stupid.

Which is why Windows is a device to me, not a platform. I wouldn't port
something that runs on a Linux server to run on Andriod, really, so why port it
to run on Windows XP? Windows is a device. Making something run on Windows is a
silly challenge like writing Moon Patrol for the vi macro language.

Fedora and RedHat give so much to the kernel, and Shuttleworth sounds like a
politician, so I'm going to move away from this and toward Fedora and the kernel
and RedHat. I am suddenly unimpressed.

The nice thing about Ubuntu was the support right at EC2.


## Fedora

 * [Create Fedora on
   EC2](http://github.com/dazed1/pvgrub2ebs/blob/master/createfedora13bootebs.sh).
 * [Fedora 13 on
   Linode](http://library.linode.com/advanced/pv-grub-howto#fedora_13).

RPMs.

http://thegrebs.com/irc/linode/2010/01/17#13:18

 * [64 bit versus 32 bit](http://www.linode.com/forums/archive/o_t/t_5570/linode_360_centos_lamp_32_bit_and_64_bit_ram_comparison..html)
 * [More 64 Bit Versus 32 Bit](http://journal.dedasys.com/2008/11/24/slicehost-vs-linode)

I'm going to go with 32 bits to get more out of the Linode, especially when the
processes are supposed to be small.

http://library.linode.com/advanced/pv-grub-howto

Contents of `/etc/sysconfig/network`.

    NETWORKING=yes
    HOSTNAME=portoroz.prettyrobots.com

HAProxy from here:

    http://download.fedora.redhat.com/pub/fedora/linux/development/rawhide/i386/os/Packages/

## Process Monitoring

Using a combination of [Upstart](http://upstart.ubuntu.com/wiki/) and
[Monit](http://mmonit.com/monit/), moving from Upstart to [systemd when it
becomes part of Fedora 15](http://fedoraproject.org/wiki/Features/systemd).

## Alan

Create an Alan account for now.

## Namespaces

Applications need to get a name like app1. That means that you can't use Puppy
to get a domain name, and there is no domain name gold rush. You have to be able
to sort out domain names on your own. That is a service we can sort out later.

Defer namespace issues. Do not create a namespace economy, because if namespace
matters, then you can't grow. Make it easy for them to CNAME.

## Monitoring

You can use cpulimit to keep a process from hijacking the system. Then you can
use a periodic `ps` to track process usage. File quota is easy. Memory quota is
going to be difficult?

Oh, wow: `/etc/security/limits.conf`.

But, the only way to see over time is to build something, ps every second, and
then use some flavor of RRS database, preferable one implemented in MySQL, to
store the results.

So, stop looking.

Splunk is the leader. Here is [a list of
alternatives](http://serverfault.com/questions/62687/alternatives-to-splunk).

## Exceptions

Charts are one thing. The other is messages. Logs create messages, some of which
are really tickets.

Capturing exceptions on the server side using `uncaughtException`. This creates
an opportunity to swallow an exception if one occurs before uncaughtException
can be invoked. Thus, startup needs to be failsafe, tested.

Assured would be to create a too simple to fail shell program that would log
stderr, and create one for each private utility. This however, would create a
great many little extra files, which may be annoying, difficult to maintain, but
I'd feel much more confident that errors were being caught.

Problem is that Node.js is young. Something might go wrong and error messages
are printed, a stack trace containing a password. If we are redirecting stderr
to a temporary file, there is no doubt that the error has been captured.

### Exceptions and Security

    [alan@postojna client]$ puppy account:register alan@prettyrobots.com ~/.ssh/identity.pub 

    /opt/lib/node/.npm/common/0.0.1/package/lib/database.js:14
          return callback(new Database(stdout.substring(0, 32)));
                                              ^
    TypeError: Object 8445ed2d7a03a2e29c47790e83d4147e
     has no method 'substring'
        at /opt/lib/node/.npm/common/0.0.1/package/lib/database.js:14:43
        at ChildProcess.<anonymous> (/opt/lib/node/.npm/common/0.0.1/package/lib/shell.js:68:14)
        at ChildProcess.emit (events:27:15)
        at ChildProcess.onexit (child_process:151:12)
        at node.js:768:9
    [alan@postojna client]$ 

Should not allow stderr to propigate back to caller, capture it and redirect it
somehow, so that execptions do not create these problems.

## Visualization

Value of Puppy over competitors will be offering visualization and remote
debugging. The environment will be command line in workflow, with an HTML 5
application for the visualizations. Our audience is UNIX devs, OS X and Linux.
Windows is not to be taken seriously, so no support for Internet Explorer.
Windows users are filtered out. They are unwanted.

(A user who can make their Windows environment UNIX like or who can run Linux in
a virtual machine is fine, but no support for people who think they can do this
sort of development from a Windows command line. They can't.)

Thus, our visualization client is an HTML 5 application. This is your project.
The user interface you create will be one that has analytics, like Google
Analytics, and messages, like an inbox. Those messages may be considered tickets
or issues.

 * Time series data, charts and graphs.
 * Messages. (Another inbox.)
 * Issue tracking. (A message is considered a problem, such as a message that
 * the process is crashing.)

Developers are going to be encouraged to write programs that crash completely at
the first sign of trouble. Analogous to the Japanese form of manufacturing
where, if you see any problem with an automobile, you stop the entire factory.

In the case of the web application, any error that occurs should crash the
instance, record the error. Then the instance can be restarted. This will happen
quickly, imperceptibly to the web application users. Someone will get an error,
but the instance will crash and start again.

This is in lieu of trying to build a program that recovers or does anything
"gracefully". Just crash and restart.

When the crash occurs, information about the crash is recorded in a message, in
log. People can be notified of crashes.

 * Email notifications.
 * SMS notifications. (Text messages.)

This is a way of building applications. Many young developers are afraid of what
it means to have problems in production. I see production as a great place to
find problems with a system.

So, these crashes are recorded for them. They become tickets, issues. You can
detect when a program is crashing for the same reason, repeatedly, and group
those messages. You can record aspects of the request. Even take actions on
crash to determine your end user, say, if you want to call and apologize (as we
often do.)

## Syslog

Going to use Syslog for logging. Syslog is limited. It is from the [olden days,
and from BSD](http://www.faqs.org/rfcs/rfc3164.html). (That RFC is not an RFC,
but a description of what exists.) It made an attempt to classify the services
available on a server, so it is has a service category for news, UUCP and line
printers. There is one user based syslog channel. There are local 0 through 7,
which are given to the sysadmin for unforseen services, but they are [mostly in
use on a Linux
distribution](http://serverfault.com/questions/115923/which-program-defaults-uses-syslog-local0-7-facilities).

At the outset, I created logs for local0 through local7 to see which services
were already using them.

To filter out messages from Puppy specific services, tags are used. Tags added
to the start of messages. Puppy specific services use a single localN. Results
are split out from there.

Recall that you once piped to vlogger for dozens of Apache hosted WordPress
blogs, so you didn't fuss much then about the notion of sending logs through a
process.

You can easily send syslog messages from Node.js, if you create a [Node.js
syslog client](http://csl.sublevel3.org/py-syslog-win32/). The source for
`openlog` and `syslog` are in glibc in `syslog.c`.

We make an effort to use syslog for all logging and configure rsyslogd to store
all logs on a server dedicated to logging. From that dedicate logging server,
reporting can be constructed.

Any server can work with syslog by piping its output to logger. It would not be
difficult to create a syslog logging service, but it is also just as easy, for
now to pipe to logger.

Remember that you can use `scp --append-verify` to copy log files from here to
there, if you are looking for a solution that does not use syslog, or for log
files that you cannot get redirected to syslog.

I can turn on UDP from syslog now that the firewall is up.

* [HAProxy does it this way, really no other way](http://www.mail-archive.com/haproxy@formilux.org/msg00129.html)
* [Use MaxMessageSize](http://www.rsyslog.com/doc/rsyslog_conf_global.html) and
  make it about 32k and then you can super error if the message is too long.
* Need a way to record buffer overruns, a place to dump files.

## JSON Logging / Application Logging

In addition to Syslog, there is an application specific logging service for
instrumentation that accepts an logs a JSON string.

## Throttle / Payment

Throttle hard until they pay.

## HAProxy

Pathway into HAProxy.

Spent a lot of time trying to figure out how to tell HAProxy to add the Host
header when the client does not add it. That would only be telnet, really, using
the one-liner "GET / HTTP/1.0". Spent a lot of time trying to figure out how to
tell HAProxy to add the Host header.

And now, painfully, it occurs to me. There is no way to determine what the host
header should be, obviously. Those 14 characters do not include a host. It would
only cound if the fully qualified request were sent in the header, which does
work anyway. A simple GET will only get you errors.

I'm finding that HAProxy cannot do too much. The best bet would be to generate a
default haproxy.cfg, but let them edit their own. There is not much and an UI to
create a complicated one, that is stupid. Let them have the run of it, build a
knowledge base, have the community understand it.

HAProxy is locked down with SELinux. A policy is generated for each instance of
HAProxy. Generating the policy is done by generating the policy files.

## DAC Security

Faith in Puppy security comes from SELinux. With SELinux enabled, the avenues
for a compromise become narrow. Puppy is a collection of separate utilities,
each executable given only the SELinux permissions necessary to perform its
task, and no more.

However, the Puppy security model is built around traditional UNIX security,
then tamped down with SELinux policy. That is, there are no objects that are
protected solely by virtue of SELinux policy.

They are protected first discresionary access control and special logins which
are governed by sudo. The special logins update a MySQL database. The MySQL
database is guarded by a password. The password is set in the per-user
MySQL configuration for the special users.

Changes to the system are performed by a worker daemon. The agent users use a
special command, enqueue, to enqueue tasks to be performed by the worker daemon.
The agent users do not perform system administration tasks themselves. They are
responsible for queuing the correct system administration tasks in the correct
order, on the correct, but they are not responsible for performing those tasks.

Deferring to a worker daemon means that the agent users can return immediately.

The agent users are invoked using ssh by a developer. The public user is public
and anyone can envoke the public user of any machine. The public user provides a
registration task, a home account lookup based on email address.

This is a public account that is wired to envoke only a specific program, a
dispatch program. That program in turn executes the correct program to perform
the task. (This separation makes it easy to write SELinux policy to transition
from the login, to the public agent, to the specific public task.)

Once registered, a user has a generated user account assigned to it, from one
of the machines. This is an account like u10001 and can be reassigned. The
client program will lookup the correct account periodically.

The user can get a shell account with that user and poke around. They can run
MySQL and import and export things.

They can run protected actions. When they do, they run trough their primary
account. 

Whey create an application, they get an initial generated user account for that
application.

Note that ssh will launch the forced command using the user shell with the -c
switch, so it is not possible to make the system more secure with
`/sbin/nologin`.

 * [Can a malicious user bypass a ssh authorized_keys forced command?](http://serverfault.com/questions/162467/can-a-malicious-user-bypass-a-ssh-authorized-keys-forced-command)

Contrary to the message above, ForceCommand will defeat subsystems. All
subsystems are disabled. If SFTP is enabled, and somehow functional for public,
it will only be able to replace the authorized keys.

TODO: You can make the common library protected from inspection by users. It is
not needed for protected tasks. They invoke private and private invokes common.
Create a common group and make the private and worker members of that group.

_Questions_

 * Does the database configuration reading program make sense anymore? Can't
   that be a file that gets read and is only read by certain users? No, this
   allows us to protect using both sudo and SELinux.

## Worker

I'm considering whether to remove the worker daemon. Why not just have the
servers send messages to each other? That way, when the user returns, they know
that the command that they requested has been performed.

The reason is coming back to me. That it will not always be the case. At some
point, the notion of synchrnous operation against a netowrk of computers is
going to break down. Something is going to take longer than the user is willing
to wait for. Something is going to require a pause.

While consdiering all this, I realize that I've got these things communicating
to each other via SSH, and that if I were to do an action that affected 12
servers, that it would be a bad thing for one to be down, or to be slow. 

And if something failed, I want to track that state, the incomplete state. This
gets built into queuing as I go along.

While considering all this, it occured to me that the MySQL database, the single
point of failure, is the place for this queue. Why am I keeping it on each
client machine? If the MySQL server is down, everything fails anyway, but now
ever operation requires every machine to be up.

## SELinux

Note: Things change and error messages start showing up. This is happening
during the Fedora 15 upgrade, `port_labelify` is spitting out error messages,
saying it cannot set the locale. You spent a lot of time editing `port_labelify`
and even started playing with `auditctl`, but the problem was revealed
immediately after running `semodule -DB` and trying again. The domain needs to
be able to read `locale_t` and cannot. You can add
`miscfiles_read_localization(port_label_job_t)` to the `worker` policy and it is
fixed. Can you please remmeber to `semodule -DB` at the first sign of SELinux
trouble?

There are two security models the SELinux security model, which is mandatory
access control, and the UNIX security model, which is discretionary acccess
control. 

Security does not depend on SELinux. SELinux is always on, but if it was
disabled for some reason, the security model still works. The DAC security model
is constantly audited and updated, but the SELinux security model paves over any
holes left open by the trusting nature of the UNIX model.

Registered users are able to log into the system and obtain a shell. Their
account is constrained by an SELinux unprivileged user policy.

In the default SELinux, the world is divided into user space and root space.
SELinux prevents users exploiting the system. SELinux prevents a compromosed
daemons from reading user data.

The one area where I'd hoped to use SELinux, but was not able to, was to protect
users from reading each others home directories using SELinux. This would mean
creating a policy per user, which was prohibitive. It would also break the
current expectations of policies that update home directories. Dan Walsh
himeslef says to use DAC for users, that MAC is to complex to manage.

There is a policy per agent, however. The launcher for every program is
constrained by a type context for that program.

Policies are built up front. Each server will have a pre-allocated set of
policies that are named for the uid of the application user. When the set is
used up, applications cannot be created.

Track how long it takes to build these policies.

How far can you pin this down? Can you label adduser and create a policy for it?
Can you avoid using the shell altogether? You should, since you're going to be
the system space.

_Impressions_

Reading about the future of SELinux with the implementation of a unified policy
manager, for both user space and kernel, one of the advantages is supposed to be
the ability to now have fine grained access to the policy itself, so that you
can write a policy that says who can write a policy. This is supposed to make
SELinux more secure, because fine-grained is greater security. This makes me
laugh. It is so counter-intuitive. I'll trust that it is correct until the
experience of those who know says otherwise. The ideal is now that the policy
management can now be managed with a policy. It is the complexity of this that
makes me giggle.

It would make more sense for someone at some point to note that SELinux provides
an ordered collection of security primitives based on the notion of default
deny to all resources. The flexibility in policy creation is for policy authors,
who are going to be a micro-community that serve millions. Few people will set
out to create a new policy. It will not be the task of the system adminstrators
of the univiersty or corporation to tune the policy for the tuning of the
policy, but until this is explicitly stated, SELinux is painful, because it is
very difficult to read about something so complicated if you don't understand
the sort of undertaking that it is. 

Sometimes, people feel that if they pull that punch, and talk about it without
bias, that it will welcome more people to learn and study, but really it
intimidates and fuels the notion that SELinux is too complicated.

It is not. It is simple. Security is complicated. Default deny is complicated.
It is strange to say mother may I before you do every little thing, but that is
default deny, and you get used to it pretty quickly.

SELinux could be about a community, sharing a lot of experience, and codifying
it into policy, if that could somehow be stated by the authors.

_Notes_

This will get rid of all of the protected modules.

    sudo semodule -l | grep protected | awk '{ print $1 }' | xargs -n 100 sudo semodule -r

_Questions_

 * Can you create a policy per user by having bash transition into a generated
   protected type? (This would save the time of assigning a type to each login.)
 * Can you create a special file type for each user and inidicate that it is
   home directory content using a type attribute?

_Answers_

 * You could make the home account entirely restricted, only able to run key
   private utilities, then piggyback on the per-application policy to transition
   the login shell to a restricted domain.

### SELinux Speed

SELinux is slow and will probably continue to be that way. It means clogging up
a queue of events for a minute for each change to the policy. Creating the port
types triggers a rebuild of the policy.

The solution to speed, besides waiting for SELinux to itself become faster, is
to increase the number of computers, so that, at least, you can provision new
servers in different places.

Also, you can not reallocate ports, so that, once allocated to a local user, the
port never goes back, so that the user always has those ports labeled for his
policy. Maybe, for the sake of not having to explain, we have a limit to the
number of ports visible. Then we can try to maybe match a user with the number
of ports he is required, too, so we're not waiting ports. That is, if a user
picks up and drops users with four ports, we select from users with four ports,
then not finding any, select with people less than four and order by number of
ports decending, then increase the number of ports.

There needs to be a maximum number of ports. Maybe a fetch of ports for an
application after the third is subject to review. Maybe they cost money?

You can load multiple ports in one invocation of SEManage, so do so. You can
add logic to the queue that looks ahead and runs all SELinux module builds at
once, then looks ahead and runs all semanage port commands at once.

At this juncture, I'm going to simply assign a single port, so I can build and
application and circle back, but I'm thinking that we can give the user three
prots, and then wait and see if anyone has any use for the other ports. I can
imagine using a second port for WebSockets, then a third for inter process
communication, but then I can't imagine why you'd want to have more ports that
this. The third port could listen for IPC or be a Web admin interface both, but
I don't see why you'd need more. Beside, you can reuse the main port, too, if
you wanted to database things.

My final thought on this is, take the policy construction out of the queue.
Remove it. Create 100 policies. Label 700 ports. Do that at once. Bascially,
create all the policies, for all the users that you intend to provision on the
machine. Policies are not generated dynamically. There is a maxinum number of
users on a machine. If you change that number, add more policies.

We still use our nice database tracking. We build them in huge batches. There is
a command line utility that sets the size. The users and ports are still tracked
in the database.

Now that the SELinux policy generation is going away, the worker daemon is much
less important. It's almost useless at this point. It would be much better to
have these tasks execute and return immediately. The only thing that dawdles it
the email message sending, but it can be sped up easily using postfix.

The only nice thing about the queue is that things are known to be performed.
It might be the case that we execute these actions remotely, on each machine,
and there is a way to execute them again if they are not marked as complete in
the database.

But everything in the worker, that creates a strange state for the user. I'd
much prefer to have the use know that their tasks have completed, the moment
that the services return.

The only thing that really challenges is updating the configuration after an
application change, if one of the nodes is out. Maybe a problem with a machine
causes it to re-run configuration prior to starting services.

Want to separate accounts with policies attached from accounts for registration.
The former are some form of expensive, I believe. In fact, you only need
policies for application accounts, which are going to be limited. So, let's
start user accounts at 20,000.

## Users and Groups

A way to get information to the owner is to be a part of their group. Therefore,
in order to enqueue, you need to be part of the enqueue group, so you can read
the private key necessary to enqueue.

## Source Control

Security becomes a problem when the keys are checked into source control. Then
need to come from some other source, perhaps copied from an existing machine.

## Firewall

Looks like I'm instaling [Shorewall](http://www.shorewall.net/). IPTables
logging requires that you explicitly enable firewall logging.

Note that, you're not going to make packets. You can use this metering.

## Monitoring with Monit/Upstart/SystemD

How to reload? Monit watches HAProxy. Upstart will watch 

## Upstart

Replaced by SystemD in future Fedora releases. Use Monit to monitor things you
trust, Upstart then SystemD to monitor things you don't.


## Configuration

File locks are here.

 * [File Access / Pleac / Ruby](http://pleac.sourceforge.net/pleac_ruby/fileaccess.html).
 * [File locking In UNIX](http://en.wikipedia.org/wiki/File_locking#In_UNIX).

Need to do it for 

## Heroku

Turns out their backups are not super garunteed.

http://docs.heroku.com/pgbackups
http://groups.google.com/group/heroku/browse_thread/thread/5bfdab913546f964#

## SSH

(Tired.)

ForceCommand: Does not work as I thought. This acticle on [Per-User
Configuration](http://oreilly.com/catalog/sshtdg/chapter/ch08.html) describes
two separate servers, OpenSSH and SSH2. I'm not able to have per-user
forced command with OpenSSH, without rewriting authorized_keys.

The problem is that the user can overwrite authorized_keys. They can write to
file because it must be readable by them, and not by everyone. World readable
works, but that doesn't feel right, users will carp when they realize that they
can read each other's public keys.

If a user damanges their installation by changing their authorized_keys file,
that is their problem. We can use inotify to detect when someone changes that
file. That file is critical. Other cleanup can be initiated by the user.

A change to authorized_keys would enqueue a reprovision or reauthorize, which
would write the keys again.

When forcing a command, the user must not be able to change the file. I'm fairly
confident that SFTP or not, there is no way to trich SSH into running anything
but the forced command. I can use an `authorized_keys_t` for the user accounts
and agent accounts to assert this.

Easier! There is already `ssh_home_t` and the restricted user profiles that I
created for forced commands does not permit `ssh_home_t` to be read or written.

### sudo

I can't determine if sharing groups is a good idea, or if I should explicitly
sudo, and have no group sharing (other than the puppy group).

Reasoning about this:

Easier to audit, since there is only one concept, the transition. You transition
from one domain to another domain in SELinux. You transition from one user to
another to take advantage of DAC.

The database password, for example, can be a program that can only be run by the
database user. It emits the password, read from a file that can only be read by
the database user.

The queue is only written and read by the worker. The enqueue user, when
launched, will sudo to worker and run a worker assignment program to spool the
task. This is where it feels wierd, because we have this user, enqueue, that
when envoked by ssh, immediately invokes sudo. This is how public currently
works however. It runs the puppy user, which is the user that can read and write
to the database.

The enqueue user invokes enqueue, so it is able to read a key that is in its
home directory, maybe that key is the default identity for the enqueue user.

Groups mean sharing. It is another dimension. Users and sudo are transitions,
much like domain transitions. It straightens out one's thinking.

Big drawback is going to be that all these little programs are going to mean a
lot of names. I'm avoiding this solution because I don't want to concoct all
these names. However...

These programs are not command line programs and they are not in the path, so
use underbars and be explicit. Not really the UNIX way, but better than making
up silly names and having to explain to people what they mean. 

## DNS

Need to propigate known hosts and host names. Currently, I'm trusting
GoDaddy.com DNS to work correctly. Known hosts is a protection against DNS
spoofing.

Use www.xelerance.com to test com domains.

### Key Distribution

Traditional DNS is easy to spoof. Anytime you've been at a coffee shop or a
hotel and a login page opens when you open any site, that is DNS trickery.

DNSSEC is a specification to secure DNS, to verify the source. It does not hide
data, keep it secret. It validates that the data comes from where you expect it
to come from.

DNSSEC is a trust based system. It uses tlds that vouch for domains. This has
not been implemented wildly. Thus, there is a look-aside validation. You can
specify places that you trust to provide you with validation and their keys.

Using this, you can put a key for puppy right into the resolver of a new
machine. You can also use [DNSSEC Look-aside Validation
Registry](https://dlv.isc.org/) to add new root keys, like a puppy key. 

With this known_hosts becomes a moot. The ssh client will lookup the fingerprint
of the machine key via DNSSEC at startup. The known_hosts files are not
maintained. Both the machine key and the machine IP address are verified with
PKI.

This is the right solution for key distribution.

Don't forget to [roll your
keys](http://whyscream.net/wiki/index.php/Dnssec_howto_with_NSD_and_ldns).

### Propigation

This was a cause for concern, trying to find a way to have immediate DNS upates,
when I realized that, hostnames, in puppy are disposable. A host name is just an
incremented number. (Notice how Amazon uses the IP address as the hostname.
Never changing. We can't do that however, because the server key is changing.)

Changes take time to propigate, but additions are immediate. A new host lookup
will always propigate back to the authoritative server. If we are adding servers
in a rush, they will be available immediately.

New servers are always added. Their keys never change. When a server is retired,
its name is never used again. The key, hostname and IP are a tuple. If one is
missing (key lost, IP reallocated), the tuple is invalid.

### Servers

Need to manage my own DNS to use this. The main contenders today appear to be
BIND and PowerDNS. TinyDNS is the DJB-ware offering. PowerDNS is the new
alternative. In reality, I only need BIND. Do not need fancy failover, or
database backed records. A master BIND server. If that server goes down, no new
servers can be provisioned until it is restored.

I'll have to bring the server up at the same IP address.

This can be done the moment I have more than one Linode. 

## Ports

Named ports have a comfort factor, but probably not going to do that. Enumerate
ports will work fine. You can build a comfort factor at the application level.

## PostgreSQL

Edit the `pg_hba.conf` to contain the following lines:

    # "local" is for Unix domain socket connections only
    local   all             all                                     ident
    # IPv4 local connections:
    host    all             all             127.0.0.1/32            md5
    # IPv6 local connections:
    host    all             all             ::1/128                 md5

This will be updated, or auto generated, for the multiple web clients to the
database server.

## MySQL

There is a V8 engine JavaScript language for PostgreSQL. That might be an
answer.

MySQL
[Meetering](http://www.mysqlperformanceblog.com/2008/09/12/googles-user_statistics-v2-port-and-changes/)
which could be used to create billing.

## Relocation

At times, I'm going to want to relocate people.

Relocating running applications remains to be seen.

Relocating logins, when people are connecting to ssh, it is done in this way...

The machine is decomissioned. The local user is flagged in an outgoing state.
An alternate is provided. If the user updates during this time, we will do the
migration. They upload to the new site.

If they connect, thier cached connection information expires every five minutes,
so they will check before they connect. If their system clock is relly screwed
up, that is not our problem.

How about, if they stage after the move, we actually deploy to the alternative
machine, we forward the stage, schedule the restart.

Or maybe we put in a forced command that simply returns an error code that is a
strange code, like 117, which indicates that we should fetch the host
information again.

We'll only be calling a `/puppy` command, so we can check the desired command in
the forced command. If it is a `/puppy` command, we return our special error
code, the one we're looking for. If it not, we return an error code, but also
print a message to standard error.

That would simply trigger a reading of the account configuration, so we can feel
confident in caching the account configuration for a period of time.

Also, if we create an app:rsync and an app:ssh, or the like, it should make life
easier. I'm not sure that people are supposed to spend too much time in SSH on
the server.

## IPSEC

Create a separate address for IPSEC. StrongSwan (or OpenSwan) listens and
creates tunnels if the traffic goes to another Puppy server. There is a point to
point route for each pair defined in the configuration file. The configuration
file is defined using an SQL join of the Machine table against itself.

Every machine has a route to the machine that hosts the MySQL database that
hosts the definition of the network. This is used a bootstrap, only this route
is defined. Then the routes are regenerated and reloaded.

The routes connect at route time, so that, like the DNS lookup method, they are
only created as needed.

Initially, I'd considered doing opportunistic routing, using the DNS lookup
method to find the public key of the destination.

 * What are the costs of each connection? This I can determine by watching.
 * Do you lose the first package with when you use "auto=route"?
 * It is possible to add DNS lookup of the public key to StrongSwan?
 * How do you ensure that communication is encrypted? What if IPSEC goes down?
 * What is the difference between transport and tunnel?

From a conversation with `x509` on `strongswan` at `irc.freenode.net`. Each
tunnel costs about 10k. He has one customer with 40,000 IPSEC connections. Each
machine will only have N-1 connections to maintain, so even if I have 48
servers, then each will only have 47 IPSEC SAs costing 470k. 1200 severs means
11.7 MB worth of connections.

Turns out that you can connect to these machines and open specific ports to
passthrough the IPSEC. That's what the proto is for. Thus, I'm going to open
port 53 for udp and ports 22, 80 and 433 for tcp.

Now by default everything is encrypted. 

## Linode

## Automated Linode Deployment

 * Disable Lassie.
 * Create deployment from StackScript.
 * Boot with StackScript for the first time, StackScript runs. StackScript will
   shutdown itself. Poll to see if the server has termiated.
 * Change to pv-grub and boot.
 * Enable Lassie.
 * When running, ssh in and run the continue script.

## Upgrading

When upgrading, these are the files you're going to want to preserve:

 * The server's ssh key.

## VirtualBox

Create a disk (4GB is good) and mount on an existing Fedora VM as the second drive.

Boot the VM.

Create a single partition on the drive.

Run the `bin/virtualbox` script.

Create a VM that has the given machine as its root.

### EC2

Following the philosophy of worse is better, I'm considering a move to Amazon
EC2, where snapshots and the like are easy, and everything now very easy to
automate. I can spin up a dozen servers for $0.24 an hour to do testing. I can
store user data on separate volumes, and begin to get some security in that way.

It depends, though. Linode was a good place to build Fedora, while the Fedora
team sorted out EC2. I don't know that I could have deployed on Fedora until
now.

It occurred to me that there's a problem with one big disk, in that someone
might be able to fish for deleted stuff by allocating blocks and searching
through them. Maybe you can find an SSH Key or something.

Anyway, I'm not enjoying my upgrade on Linode. I must shut things down, rebuild,
then spin them up. Each deployment costs something.

However, 200 GB of transfer is $20.00. That is worth something. On the other
hand, a 3 year term micro instance is $7.41 a month. 

My thoughts on this are flow as follows:

 * They [make their money off the
   bandwidth](http://gigaom.com/2009/07/17/the-hidden-cost-of-the-cloud-bandwidth-charges/).
   I'll never make money because all the margin is in the bandwidth, and they
   the the prices maxed out.
 * I could sell Linodes bandwidth, but then it runs out, but then I'm still
   making 0.05 when I order more.
 * I could make the money, if I built my own hardware.
 * I would then be in the hardware business, instead of building hosting
   solutions, so I'm in trouble. That is a hard choice to make.
 * I can establish the business with Amazon, then move to Linode when I'm ready
   to make the money, the service has stabilize.
 * Linode disk space is very expensive. $2.00 a GB extra, instead of $0.10.
 * The machines are a loss leader, so if you had a business that made moeny off
   of calculations, then you could get a subsidy from Amazon.
 * Selling processor space does not scale well at all, the biggest cost will
   always be bandwidth. You can charge 0.03 an instance hour, but that is going
   to be only a couple bucks a month.
 * If you grow the business and you finally reach 10TB, then your costs drop to
   0.11 and you immediately make $400.00 profit.
 * Now I'm starting to see how I can pass the saving along to customers who hit
   certain levels, to goose along the bandwidth, to get to the point where I'm
   making money off of bandwidth.

And so, now I have an EC2 based business plan.

 * MongoDB and MySQL charged by request at 0.10 per 100,000 requests.
 * 0.01 per instance hour of application.
 * Storage is 0.20 per GB.
 * I/O is 0.10 per 100,000 I/O operations.

### EC2 Fedora 15

More of a journal for now, until I learn more about how to organize the Ec2
systems. This is for 64 and 32 bit.

Run the difference scripts to remove unwanted RPMs. (Need to put these
somewhere.)

Create an alan user, add your .ssh key. Ensure that you can login as the alan
user. Remove the EC2 user.

Now snapshot the system. See if you can bring up a new instance of the system.
See if you can log into the system. Let this be your new master system.

Save a snapshot now in case things don't work out. See if you can boot the
snapshot.

Checkout Puppy. Run puppify. It's a good way to get things rolling. 

[Shrink](http://serverfault.com/questions/183552/shrinking-amazon-ebs-volume-size)
the volumes at some point.

### VirtualBox Checklist

 * Create disk.
 * Attach disk to a working Fedora.
 * Create a single partition on disk.
 * Create ext4 filesystem on disk.
 * Run `bin/virtualbox`.
 * Unmount disk.
 * Boot with own VM.
 * Connect as root via ssh.
 * Run the `/root/bootstrap` script.
 * Reboot.
 * Run `bin/puppify`.
 * `ssh` to `puppy`.
 * Install `build-essential`.
 * Build a `node` for `/opt`.

### Installation Checklist

 * Turn Lassie off.
 * Generate a temporary ssh rsa key to use with stack script.
 * Run StackScript.
 * Log in using temporary ssh rsa key. Do NOT `ForwardAgent`. Check fingerprint
   after logging in.
 * If fingerprint checks out, replace public key with alan public key.
 * Log out and log back in.
 * Add the hostname to DNS.
 * Set reverse DNS.
 * If the server will be a namesever, add its Host Summary record at GoDaddy.com.
 * Temporarily establish Linode nameservers. 
 * Configure `/etc/sysconfig/network-scripts/ifcfg-eth0` to use static ips and
   not dhcp and configure additional public interface and private interface.
 * Change hostname to new hostname, reboot.
 * Generate SSHFP records with `ssh-keygen -r hostname` and add to DNS.
 * Login as root and run `./continue` then `./bootstrap alan`. The current RSA
   fingerprint is `e7:7b:0b:62:af:67:23:f9:0e:e3:1c:63:b1:e4:d9:3d`.
 * Run `bin/puppify` to configure sshd and create users.
 * Restart `sshd`.
 * Copy an `/opt/` directory using
   `sudo -E rsync -av -e "ssh -o VerifyHostKeyDNS=yes" --rsync-path="sudo rsync" /opt/ alan@z1.dallas.runpup.com:/opt/`
   and copy `/node/` using similar.
 * Add `VerifyHostKeyDNS yes` to your `~/.ssh/config` and `chown 600 ~/.ssh/config`.
 * Start unbound.
 * Change `/etc/resolve.conf` to use localhost.
 * Copy over your environment using
   `bin/emigrate alan@z2.dallas.runpup.com .vim/ .usr/ .bashrc .bash_profile .vimrc .gitconfig`.
 * Run the checkout script to checkout puppy.
 * Run `bin/harden`.
 * Create a link to `/opt/bin/node` in `~/bin`, log out and log back in.
 * Install `npm` with `curl http://npmjs.org/install.sh | sh`.
 * Install `coffee-script`, `mail` and `mysql`.
 * Run deploy for `liminal`, `janitor`, `common`, `protected`, `private`,
   `worker`, `vhosts` and `public`.
 * Add the correct interface IP to `/puppy/etc/address`.

This applied to OpenSwan.

 * Regenerate the IPSEC key cache with `certutil -N -d /etc/ipsec.d`.
 * `ipsec newhostkey --verbose --configdir /etc/ipsec.d  --output /etc/ipsec.d/keys.secrets --bits 1024 --hostname z1.dallas.runpup.com`

### Compiled

Build as `puppy`.

 * Build node with `./configure --prefix=/opt`.
 * Build node with `./configure --prefix=/node/v0.2.6`.
 * Build unbound with `./configure --prefix=/opt --disable-gost` you'll need to
   `sudo yum install expat-devel ldns-devel openssh-devel`.
 * Build haproxy with `make TARGET=linux26 CPU=i686 USE_PCRE=1`. You'll need to
   `sudo yum install pcre-devel` first.
 * Build stunnel with `./configure --prefix=/opt` after applying the PROXY
   patch. Only the PROXY patch, since you have to choose between 4.33 and 4.34.
 * Build StrongSwan with
   `./configure --prefix=/opt --disable-pluto`. You won't be able to get it to
   put its configuration in `/etc`. You'll have to symlink `/opt/etc` to `/etc`.
 * Install `npm`.
 * Install `coffee-script`, `mysql`.

Needed to build MongoDB:

    sudo yum -y install git tcsh scons gcc-c++ glibc-devel
    sudo yum -y install boost-devel pcre-devel js-devel readline-devel
    #for release builds:
    sudo yum -y install boost-devel-static readline-static ncurses-static


## Upgrade Questions

 * Are there any questions that you are forgetting?

### Bootstrap

 * Has `/etc/bashrc` changed in a way that will cause `bin_t` labeled programs
   to be executed? This is a problem with the public agent, which has a minimal
   login.
 * Has `/etc/bashrc` changed in a way that will defeat the modifications made to
   id in puppify? The puppify script alters a conditional that would otherwise
   execute a program, which is denied the `public_t` domain.

## Security Questions

 * Are there any questions that you are forgetting?

### Public Agent

 * Has someone changed the authorized_keys file?
 * Has someone disabled the forced command?
 * Has someone enabled an SSH subsystem?
 * Has someone enabled port forwarding?
 * Has someone enabled X11 forwarding?
 * Has someone enabled agent forwarding?
 * Has someone releabled the public home directory?
 * Has someone reassigned the SELinux role for public?

### Worker

 * Does the current sudo configuration permit the use of sudo as root without a
   tty? (This is needed for the Upstart starup script.)

