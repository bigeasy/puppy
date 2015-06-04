## VirtualBox

Start with a bare Fedora 18 installation and create a First Boot snapshot. The
Fedora 18 base from which we build a server should at least allow connection via
SSH to an account that can sudo. In the case of AWS, that is the ec2-user. In
the case of VirtualBox, that can just as easily be root.

The minimum install is a verified server key, a sudoable account, and an
interface that will always come up correctly. This is setup by the puppy builder
program on AWS automatically, but it is spun up a little bit on the server side.

## Wager

Puppy is based on these assumptions.

 * **Evented I/O** will greatly reduce the CPU and memory load for hosting over
   the last fashion wave of Ruby on Rails and J2EE before that.
 * By returning to multi-tenant hosting, and taking advantage of Linux control
   groups, in lieu of virtualization, resources can be flexibly allocated to the
   customer processes that need it most. This is the finance of computing. It
   will be cost advantage. I'll have spare resources for visualization and
   monitoring.
 * The **security threat of multi-tenant hosting is mitigated by SELinux** and
   manditory access control. The security model for any object is expressed
   twice, first using discretionary access control, via UNIX permissions and
   iptables, chroot, then again using SELinux policies.
 * Template based solutions are the best solution for a majority of
   applications, so a **structured, evented template language is superior to
   MVC**, and worth the complexity costs of building tag libraries, which are
   conceptually more difficult than models and controllers, but simpiler on the
   other side of the learning curve.
 * Pricing is set by a markup on **Amazon EC2** which will always have the
   **lowest price for scalable resources**. Amazon EC2 costs reflect the real
   costs of hosting. There is a $30 dead zone that is not worth filling, after
   the price is noticiable, before it is comperable to the people who offer a
   chunk of free transfer.
 * Organic growth is possible by selling at the outset and dwindling the
   reserve, using the up front to pay Amazon. Customers must consume the
   capacity that they reserve, so there is no turning off and on the control
   group you hire, because I can't afford to keep a computer around for you to
   use if you choose to use it.

## Advantage Puppy

Take advantage of the Puppy architecture to succeed through organic growth.

 * Worse is better. Organic growth is possible by embracing the practical,
   understandable, simple approach, even if it is slow, lossy, inelegant by
   someone's measure of elegance. See `bash`.
 * Use EC2 to build images, audit them as black boxes. You cannot know all there
   is to know about a machine. You do not gain more knowledge by running `yum`
   for each `rpm` you install. You will know your machines through their
   behavior, not their binary representation on disk.
 * CoffeeScript and `bash` for great justice. Use `Perl` when you are too lazy
   to write something in `bash`. Use a `CoffeeScript` daemon of performance is
   going to be an issue.
 * Zen like workflow through and through. Use Puppy, manage Puppy, and bury the
   costs of SELinux policy reloads and other tedious processes, through
   evolution of images and scripts.
 * Learn by doing. You learn more through experiementation than by, say, reading
   every post in your many listservs.

## Concerns and Decisions

Here are questions that I'm pondering at the moment.

 * Storage of private key material; where to put it? For pedestrian users I want
   to have a simple message; don't lose your login, but I'd have to add, don't
   lose your private key. Key management is handled by GitHub's Mac client, for
   example, and I expect that Puppy users will want similar ease of use.

## Going All EC2

After all the energy I put into PostgreSQL, it is saddening to think that I'd
give up on it and use DynamoDB and SQS, but that is probably the shortest path.

 * https://forums.aws.amazon.com/thread.jspa?threadID=16558

## EC2 Architecture

There are three types of machines, `user`, `balance` and `data`. Each of the
machines is numbered in order with a prefix `z1`, so that there is a `z1`, `z2`,
`z3` and so on.

Note: Not at all settled on this naming convention.

There is an additional `conf` machine that is synonymous with
`z1.balance.runpup.com`. The `runpup.com` name servers are spread across the
`balance` machines.

A new machine is allocated by creating the necessary DNS entries, generating SSH
keys in the configuration directory, and allocating a new public IP address, the
the machine is going to be a public machine.

A machine can then be spun up by passing the machine's hostname as user data.
The machine will rsync it's configuration from `conf.runpup.com`, including SSH
keys, so that we can use DNSSEC to connect to the machine for the first time,
and be confident that the fingerprints are correct.

    ec2 RegisterImage \
        Name 'Puppy Fedora 15 64' \
        Description 'Puppy Fedora 15 64' \
        Architecture x86_64 \
        RootDeviceName /dev/sda \
        KernelId aki-427d952b \
        BlockDeviceMapping.1.DeviceName /dev/sda \
        BlockDeviceMapping.1.Ebs.SnapshotId snap-7afe0e14

## DNS

Create a local area network DNS with
[Unbound](https://calomel.org/unbound_dns.html) and local NSD server. Ah, but,
worse is better. Why not just have the global DNS resolve to the local network
anyway? What will someone do with the DNS lookup, and can't they perform it
anyway from the shell of a Puppy account? My only concern is someone spoofing,
by getting a DNSSEC validated lookup, put putting a machine somewhere else.

Except that, you'd be connecting to bouny.data.a.virginia.runpup.com, which
isn't going to mean much, and it has to be on your local network.

## PostgreSQL 

Everything about PostgreSQL durability and availability is wrapped up in the
write ahead log. You use it, not only to do replication, but also backup. It is
confusing because there are some utilities that look the primary backup
utilities for PostgreSQL, and because WAL based backup comes last in the manual,
but the WAL based backup is what everyone talks about online.

The WAL is what they've come to depend upon. The PostgreSQL community has a lot
of faith in it. We're going to have a lot of faith in it too.

Thus, when you revisit this, skip to the last [backup offering in the
manual, Continuous Archiving and Point-In-Time
Recovery](http://www.postgresql.org/docs/9.0/interactive/continuous-archiving.html).

The current strategy for PostgreSQL durability is to do failover, with a
convoluted double HAProxy proxy. This has been scripted. The documentation is
going to live primarily in comments in the scripts.

Currently, you have both WAL shipping and the streaming replication configured
in PostgreSQL. Good for you.

We want to survive the failure of an entire availability zone, for the duration
of the failure of the availability zone. Thus, we log ship to the other
availability zone, where the logs are going to live on the balance machine. If
the master fails, the standby comes up and ships logs to the same server. This
is a balancing act, if the standby zone goes down at this point, we are out of
service, we did not survive a major Amazon failure. Bummer.

That wasn't Very Serious, was it?

I might draw this up with a OmniGraffle, so that I'll remember this. In essence,
we fail over to the standby server in the standby zone. The standby server ships
logs to the standby balancer in the standby zone, while we frantically restore
the master. The master is up and running, so we do a WAL backup of the standby
to the master. We then restart the standby as a master with master as a standby.
This is fine for a while.

It doesn't really matter where the logs are shipped, does it? If the master goes
down, the master goes down. The logs are being updated using streaming
replication. The question to ask is, do we read the shipped logs when streaming
replication is active? Probalby, yes, but they logs are all applied, so they get
deleted.

The WAL shipping is a good way to get things rolling, I think.

Anyway, we restart the standby as a master, and the master as a standby. We wait
a few minutes and then we fail over. We then repeat the process, without the
final failover.

Thus, we need something that will detect failure and trigger a failover.

We also need a structured failover. Two distinct units.

Starting out with HAProxy and three servers. One is a bogus server that goes
nowhere, the other two are the primary and secondary servers. The primary and
secondary are disabled.

 * [HAProxy 1.5 Configuration](http://haproxy.1wt.eu/download/1.5/doc/configuration.txt)
   &mdash; Live it!

Double HAProxy is easier to understand, maintain. Simply kill the proxy. The
primary proxy will never get recofigured, so when you kill the secondary, it can
simply reload. Maybe you put that primary proxy on the user machines. They can
connect only to the primary proxy, they cannot go out. That proxy is up all the
time, it has the right port number, etc. It goes to the balance machine using
the public IP, so that if the balance machine fails, we can bring it up with a
new IP. While the balance machine is down, things trap at the web machines.

## Copacetic

 * **audit2allow** &mdash; Run audit2allow and filter the output. If the events
   are expected, ignore them, but if new events occur, issue a warning. Run
   semodule debugging always, to see all the messages.

## Tasks

A cookbook for puppy maintainence.

### Restarting public DNS.

Primary public DNS lives at Virginia with a secondary at Linode. You can
terminate the primary instance and restart it simply enough. When it restarts,
you need to first install NSD, then run `/root/setup.sh`, then run
`bin/dns/public/publish`.

### Building a Puppy Image from Fedora Image

There is a bootstrap script that has become the defacto script. Launch a
starting image and from there run the boot script either as root, or using sudo,
but providing the environment to include the SSH agent.

The script will install the necessary pacakges.

You can strip out unneeded RPMs from the starting image by diffing. Get a list
of installed RPMs on a working Puppy.

```
rpm -qa | sort | sed 's/\(.*\)-[0-9].*-[0-9].*/\1/' > previous.txt
diff previous.txt next.txt | grep '^>' | cut -d' ' -f2 > differences.txt
cat differences.txt | xargs sudo rpm -e
```

Edit `differences.txt` until the last command runs correctly, removing stuff
that is necessary in the newer distribution.

Yes used `rpm -e`. No do not use `yum remove`. The latter will solve
dependencies and destroy everything.

Make the machine your own by copying over your user configuration from another
Puppy machine like so.

```
bin/emigrate alan@z2.dallas.runpup.com .vim/ .usr/ .bashrc \
    .bash_profile .vimrc .gitconfig
```

Add your public key to your user. Remove the default init script. You can remove
it in Fedora 16 by remove the cloud init stuff. You'll only be able to login
using your public key. Make sure you can login with your public key before
making your AMI and destorying your working instance.

To mount the S3 images, you need a `/root/.s3cfg` from an existing image.

### Creating A Puppy Machine Instance 

Use `bin/image/create` on a machine that has `/mnt/config` mounted. Then do a
snapshot of `/mnt/config`.

### Creating a Puppy AMI

Use `bin/image/foo`.

### Exim

Exim forwards email to remove users. It must not allow users to email each
other, but it needs to allow failures to return the sender.

## Journal

MUST TEST that mail is not sent, sendmail was installed and it was not
restricting who can send.

### Sat Mar  2 05:03:59 EST 2013

Exim looks like it is going to do what I want it to do with per-user
configuration of relay hosts.

### Sun Dec  4 02:45:46 EST 2011

Wondering if it a case for security, to have a janitor, someone who can do
anything, who is audited to high heaven, perhaps, but can do anything, because
it becomes a tradeoff. Let's say I deploy a server into the wild and there is an
SELinux policy problem that prevents the janitor from doing something vital. I
might have deployment image, that image has a severely constrained janitor, and
a development image, where I am unconstrained. The concern is that my
unconstrained image is how I work, but the production image is the image that
does the work. If it does get compromised, I'd be in a strange situation where
the attacker would have higher privileges than the administrator.

The administrator could be, or the developer user, could be a user that doesn't
exist. The user is removed from the system. The first step would be to add the
user to the system, via the janitor.

Maybe we invoke the janitor from a master controller, the developer.

This continues to be confusing. It would be better to take one position or the
other. Until I'm able to sanitize the janitor, why not give him a strong role?

Or do I work harder to treat these machines as appliances?

I'm afraid that by locking these machines down tightly, I'm going to destroy
user data, which is just as bad as security.

If each action of the janitor is clearly defined, then there is no bombing
about, trying to figure things out. You create a policy for every action on the
machine, and anything that appears in the audit.log is a problem.

But, default SELinux is not defined this way. Some messages get eaten. You might
have errors that are unreported. You can find some other way to measure success.
Did you get the correct outcome?

You can create permissive policies for new projects. You can give the janitor a
permissive role during development. No, because creating policies is part of
development. You definately want to design things so that they start from the
janitor, even if you are starting them up remotely. Maybe you don't want to be
editing and bombing around in AWS. It will be very difficult to develop if you
have to edit a policy just to run a program.

Create a janitor that can do everything, but with a mind to making each task
it's own task. However it is, it needs to be simple and inevitable.

```
sudo -E rsync -a -e "ssh -o VerifyHostKeyDNS=yes" \
    --rsync-path="sudo rsync" \
    alan@alvar.balance.south.virginia.runpup.com:/mnt/puppy/node/ /node/
```

### Sat Dec  3 08:16:31 EST 2011

Here's my latest thinking. I need to be the janitor. I act as the janitor. Then
I take my actions and automate them. If you're the janitor, you can do anything,
really, but hmm...

If there was an automated way to create SELinux policies, then I could be Alan,
but I could create policies for those things that the janitor does. I'd have to
remember how to create policies, but it would be the case that I'd automate
their authoring. Running the policy over and over, until the action passes.

Currently, I'm working on creating some PostgreSQL failover strategies.

How to I work my way through Puppy? Partially by keeping it running the whole
time. It should be the case by now, that all that I've created will restart and
fall into place.

```
rpm -qa | sort | sed 's/\(.*\)-[0-9].*-[0-9].*/\1/' > here.txt
```

### Sat Dec  3 00:52:41 EST 2011

Start with a Fedora 16 AMI. Update with yum. You'll get a new kernel and a new
SELinux policy. Touch `/.autorelabel` and reboot.

### Mon Jun 27 07:23:26 EDT 2011

**How will you visualize process monitoring?**

**What is a healthy state?** You need to be able to return to that state.
Anything less that a healthy state is a cause for emergency. You can't design a
system to run in three different states. It is either stable or degraded.

### Sat Jun 25 10:53:05 EDT 2011

`systemd` will timeout if a process is respawning too fast. Can track this and
report to developer by reading through the logs. Will use the timer in lieu of
cron, to test for health of processes, introduce chaos.

### Mon Jun 20 07:46:22 EDT 2011

Deploy PostgreSQL 9.1 Beta 2.

Varnish list has some interesting things about HTTPS and logging.

### Sun Jun 19 18:37:27 EDT 2011

Questions on PostgreSQL:

How does pgpool handle failover and how does it handle recovery? Can I do the
recovery steps myself?

Assuming a judgement day failure, an entire data center is out, so the standby
promoted to primary needs to keep archiving its logs to the same archive
directory. Is this true? Can it send WAL logs to the same directory, or will
that begin clobbering data somehow.

Does pgpool have the concept of a hard failover versus a soft failover? What
about an opportunitistic failover? The last would be a schedulered failover that
would trigger when traffic had reached a low.

The WAL log archive, should it be on a RAID volume? Should it be on a DRBD
volume? 

How do you implement chaos. Can you schedule it? Then can you see how long it
takes you to recover?

### Sun Jun 19 12:48:34 EDT 2011

Links on filesystems and LVM:

 * [XFS](http://xfs.org/index.php/Main_Page).
 * [PostgreSQL and XFS](http://groups.google.com/group/pgsql.admin/browse_thread/thread/d3556df78eef78fe/2b343ba58ee3c784).
 * [PostgreSQL on XFS* experiences?](http://groups.google.com/group/comp.databases.postgresql.general/browse_thread/thread/9a532b60ed33dfed/aa87f5aae13a7551)
 * [PostgreSQL and XFS filesystem](http://groups.google.com/group/pgsql.admin/browse_thread/thread/d3556df78eef78fe/2b343ba58ee3c784)
 * [Convert EC2 data filesystems to LVM for Drupal & MySQL](http://croome.org/content/convert-ec2-data-filesystems-lvm-drupal-mysql).
 * [Amazon EBS Snapshot Backups with LVM and XFS](http://ericmason.net/2008/09/amazon-ebs-snapshot-backups-with-lvm-and-xfs/).
 * [RAID and LVM on Amazon EC2 (part I)](http://debianzone.org/raid-and-lvm-on-amazon-ec2-part-i/).
 * [Recompiling kernel modules for EC2 instances](http://blog.dbadojo.com/2007/11/making-logical-volumes-on-ec2.html).
 * [Making Logical Volumes on EC2](http://blog.dbadojo.com/2007/11/making-logical-volumes-on-ec2.html).
 * [MySQL Backups using LVM snapshots](http://blog.dbadojo.com/2007/09/mysql-backups-using-lvm-snapshots.html).
 * [More Notes On EC2 And LVM](http://heftagaub.wordpress.com/2008/04/08/more-notes-on-ec2-and-lvm/).
 * [DRBD, LVM, GNBD, and Xen for free and reliable SAN](http://www.peakscale.com/archives/gridvm/drbd-lvm-gnbd-and-xen-for-free-and-reliable-san/).
 * [A simple introduction to working with LVM](http://www.debian-administration.org/articles/410).
 * [Common threads: Learning Linux LVM, Part 1](http://www.ibm.com/developerworks/linux/library/l-lvm/).
 * [LVM HOWTO](http://tldp.org/HOWTO/LVM-HOWTO/).
 * [Logical Volume Manager (Linux)](http://en.wikipedia.org/wiki/Logical_Volume_Manager_%28Linux%29)

### Fri Jun 17 09:52:22 EDT 2011

Going to use
[pg_archivecleanup](http://developer.postgresql.org/pgdocs/postgres/pgarchivecleanup.html)
somehow.

### Mon Jun 13 15:07:33 EDT 2011

How to maybe use HAProxy to balance PostgreSQL. Start with a [complicated recipe
for a complicated MySQL
setup](http://www.alexwilliams.ca/blog/2009/08/10/using-haproxy-for-mysql-failover-and-redundancy/).
This creates a bunch of little test servers that are wrappers around
[xinetd](http://www.xinetd.org/). You will have to [know HAProxy 1.5
well](http://haproxy.1wt.eu/download/1.5/doc/configuration.txt). You can see
what it is like to simply [queue
connections](http://flavio.tordini.org/a-more-stable-mysql-with-haproxy/comment-page-1)
and go from there.

In any case, you need to configure [streaming
replication](http://wiki.postgresql.org/wiki/Streaming_Replication) first, then
configure your balancer, be it pgpool or HAProxy.

### Sat Jun 11 09:20:24 EDT 2011

Needed to patch the systemd service installation in strong swan to add the
`/opt` prefix, otherwise it installs she strongswan.service into root `/lib`.

### Fri Jun 10 06:57:25 EDT 2011

[systemd reexec needs to be
synchronous](https://bugzilla.redhat.com/show_bug.cgi?id=698198) - This is a bug
that causes the message:

    Non-fatal POSTIN scriptlet failure in rpm package glibc-2.14-2.x86_64
    /usr/sbin/glibc_post_upgrade: While trying to execute /sbin/service child exited with exit code 1
    warning: %post(glibc-2.14-2.x86_64) scriptlet failed, exit status 1

### Tue May 31 00:37:52 CDT 2011

Need to [rollover my
DNSSEC](http://www.potaroo.net/ispcol/2010-02/rollover.html) keys every three
months or so, or hey, every month. I'm going to implement rollover tonight, to
see if I understand it. Then I can put rollover into a cron job somewhere.

### Mon May 30 14:47:08 CDT 2011

Cannot use VPC. It is only available in one availability zone. That zone happens
to be my b zone. My b zone is the one that went down during Judgement Day. I'm
going to rejigger so that b is secondary to all, it is the dev replicant.

I was going to use this snippet:

    alpha ="abcdefghijklmnopqrstuvwxyz"
    ip = alpha.indexOf(char) * types.length + types.indexOf(type) + 1
    ip = "10.0.0.#{ip}"

to assign a private IP. However, I now have to find a way to create dynamic DNS,
without an IP, by listing instances or something, generating a zone file. Then I
need to tell the client machines to clear their unbound cache.

### Sun May 29 21:14:34 CDT 2011

For caching, we can use
[Squid](http://dotimes.com/iscale/2008/04/benchmark-caching-of-varnish-and-squid-again.html),
which is older, therefore I assume it is 32 bit. It will not perform as well as
Varnish. Some of the 64 bit creatures are going to be faster, because they let
Linux do all the memory management, using mmap. 

Puppy can't use it, because 64 bit machines kill the pricing model. We need  to
be able to scale with 32 bits. Every techonology needs to be able to move from
32 bits to 64 bits without a change in the underlying code.

Varnish might still be the right answer, on a 64 bit micro instance. Only
benchmarking will tell. The balance server can be a 64 bit machine.

Again, the problem with MongoDB is that it has no accounting, no multi user. You
won't be able to bill for it. You could only see micro instances. You're giving
people no way to scale, so there will be a lot of chatter between you and
customers, and you won't have good answers.

### Sun May 29 21:04:29 CDT 2011

Staying busy on the train. There are things that are going to be silly and
painful to maintain in VirtualBox. How do I test failover? I was considering
using control groups to simulate control group failure, and then you'd only need
two machines, or three, and you could move from control group machine A, to
control group machine C, when control group machine B fails. This is a layer of
abstraction so that I'd be able to run all of Puppy in a simulated environment,
on three virtual box instances, running on my laptop.

That's an awful lot of fakery. It is probably enough to simply work on Node.js
projects on my local Fedora 15, and continue to work on Puppy using Virginia
east/west at Amazon EC2. Development could take place on six machines, and when
I check in changes, I can bring the six machines down.

Consider [cognative
dissonence](http://en.wikipedia.org/wiki/Cognitive_dissonance) and cognative
disequilibrium, in the way in which you're trying to develop your software. When
you are trying to hold two different ideas, or conflicting goals, I need to be
able to scale using the cheapest 32 bit hardware in the cloud, and also run on
my MacBook, these conflicting goals are painful to consider. If you work only on
Amazon S3, your going to start to liberate your thinking, and you're going to
make software that is well evolved for life on Amazon S3.

### Sun May 29 20:40:45 CDT 2011

Turns out that I don't like `conf.ruppup.com` as a special case. I'd like to
know that all of the machines startup with the same simple bootstrap, that there
isn't a separate one to test everytime.

Mohan suggested S3. I did not like the idea of using something like s3sync,
because I don't want to add Ruby as a dependency. I like the rsync idea.

Yet, it occured to me, somehow, to create a disk image on a loopback device, and
put that in S3. You can event encrypt the device for good measure. This device
can contain only the host information, the host keys and startup scripts. At
startup, this is a simple get, using `curl` to fetch the image. Then the image
is mounted, the configuration is synced, the image is unmounted, then scrubbed.

We keep the image on some working machine somewhere, maybe in VirtualBox. There
is a script that will post the image to an S3 block store.

We may as well create a separate image for the DNS. I suppose they can both live
on the same machine. Setup for the DNS master will pull and mount that image.
They can live there so we can pseudo-snapshot them in one swoop, or they follow
a convention and there is a general psudeo-snapshot utility.

I've found `s3cmd`, which is a binary, and part of Fedora 15, so this boot
procedure works for the unmodified Puppy instances, we don't need to have
Node.js installed.

Now we can get our servers up and runnig easily.

### Sat May 28 16:58:20 CDT 2011

Buiding out Amazon EC2 today. Creating a script from Node.js to launch
instances.

VPC starts with three options. The latter two are for IPSEC from an external
data center into Amazon EC2. The first two are a public (to my mind private)
subnet, or two subnets, one that can route to the internet, one behind NAT. The
NAT machine is a machine that you pay for, so I'll take the minimal VPC.

### Sat May 28 02:09:33 CDT 2011

Naming is difficult again. I'm creating a utility to launch machines, and
specifying endpoints, zone and type, but the type is already in the domain name,
so why not put the availability zone. That would pretty much describe the
machine at the point of launch, or from the outside.

Machine names: `alix`, `bouny`, `clio`, `dupre` or `desire` or `delery`, `eads` or `erato`,
`fig`, `girod`, `odin`, `piety`.
`alabo` is good too. Oh, my. `lapeyrouse`. 

### Fri May 27 22:19:37 CDT 2011

Availability strategy.

`z1.balance.runpup.com` is also `conf.runpup.com`. If it fails, the balancers do
their failover, while `z1.balance.runpup.com` is brought back up.

Failed instances are *shot in the head* and collapsed immediately. If PostgreSQL
fails, then the whole server is brought down even with other services on the
same server.

For those services experiencing a failure, the transition is violent. The
balancer will bring them down and switch. The rest can be transitioned in a more
orderly fashion. The other server is up. Failover to the slave. Make the slave
the master. Unmount the defunct master. Mount in the new location as the slave.

This is for the economy of having a single server serve these drives.

Also, there are pricing problems with your database strategy. The instance hour
to run the database is not accounted for. It might be really cheap though.

### Fri May 27 18:04:42 CDT 2011

Use SELinux in this way.

 * Create a bottle in which to place users.
 * Protect ports from hijacking.

When writing jobs, remember.

 * Domains are not reusable, you don't have domains you can fall back into
   available in the targeted policy. Targeted means targeted. You must create
   your own. Don't waste anymore time on the bright idea of looking for them.
 * Let audit2allow do the work.
 * If you feel like one job is allowed to do too much, simply break it up into
   smaller jobs. Create files in one job, restore their context in another job.

You just fretted how to invoke a systemctl reload, after creating the systemd
unit file for a user dameon. You found the real Fedora 15 reference policy.

    yumdownloader --source selinux-policy-targeted
    rpm -ivh selinux-policy-3.9.16-24.fc15.src.rpm 
    rpmbuild -bp ~/rpmbuild/SPECS/selinux-policy.spec

The Fedora 15 patched source is found in `~/rpmbuild/BUILD/serefpolicy-3.9.16`.

Remember also that you're using systemd for limits.

### Sun May 29 12:56:38 CDT 2011

MongoDB wants [big
machines](http://www.slideshare.net/jrosoff/mongodb-on-ec2-and-ebs) and lots of
them. Giving people a dedicated machine at EC2 is not going to work. Looking at
the [pricing for Mongo Machine](https://www.mongomachine.com/), I can see that
they don't have the metrics down yet, either. They say that users are paying an
average of $5.35 for a database, so that means that people are using the $25
solution and putting 5 databases on it.

Mongo Machine has [excellent docs](http://docs.mongomachine.com/).

More [pricing from MongoLab](https://mongolab.com/about/pricing/).

How do I give people a small document database to start? They have analytics at
Mongo Machine. Can I keep people under a certain database size? I'm going to
have a pain point when they reach beyond half a GB and the machine starts
swapping.

Because a large instance is $244.80 a month. Replication for that means $489.60
And then MongoDB wants to grow and consume memory, so I'm really selling the
memory. Where do they get their prices? They must be building their own
machines. On Amazon the Mongno Machine FAQ says that MongoDB costs $350.00 a
month.

GlusterFS is not going to work. It will require an enormous amount of resources,
to do something that doesn't matter that much, since you could just as...

Was going to say, just as easily use RAID. Of course, that doesn't deal with the
availability zone problems. 

The only way to offer MongoDB would be to give a user thier own instance, then 

Note from [MongoLab](https://mongolab.com/about/faq/) that is relevant to EC2:

> On Amazon you can connect to your database using the same address both from
> outside and from within EC2. This is because if you are connecting from within
> EC2, Amazon will automatically route your network traffic using the host
> machine's internal EC2 IP address.

Why not just punt to MongoLab? They have a free offering. Users can use that.
You can build your own Puppy based data store.

DRBD is built right into Fedora and the 32bit distributions. You can create a
mount point in the user's home directory called `/sync` and then can consume as
much replicated storage as they like. They have to turn it on.

You can build DRBD directly on an EBS volume, then circle back and learn about
LVM and software RAID. Although, DRBD does have checking of its own. It will be
a while before I'm feeling at all confident in EBS volumes.

DRBD is in the kernel. It is merely an RPM install. There's no FUSE nonsense.
There's no NFS to worry about.

That checking, between hosts, is going to cost money, so you need to put that in
the cost of the hosting.

However, I do need something for failover, so I can have an available hosting
platform.

I can wait for [ceph](http://www.ece.umd.edu/~posulliv/ceph/cluster_build.html),
which looks so ambitious. 

Which means I'm stepping back from 64bit, hosting NoSQL databases, because that
is a special business. They [all want
cake](http://kkovacs.eu/cassandra-vs-mongodb-vs-couchdb-vs-redis). They all want
all the memory they can have. That is expensive. I'm happy to sell it to you,
but only if I can put a price on it. MongoDB is so flakey. It's going to keep
you up at night.

Oh, also, [no useful
metrics](http://www.mongodb.org/display/DOCS/Monitoring+and+Diagnostics) in
MongoDB, certainly not by database or user.

High memory runs counter to my strategy. This is software finance, moving the
resources to where they need to be. Don't keep it in memory if you don't need 
it. Especially when you can charge them for the I/O, but you can't charge them
for the memory.

Remember your many reasons for not using MySQL. Do not return to MySQL.

You need to also add Sphinx, or some form of full text search.

### Fri May 27 17:04:27 CDT 2011

Can I make a throw away decision about standard error?

### Thu May 26 11:49:59 CDT 2011

Find something better to do with standard error and standard out. I'm not sure
what to do, but something, and better. I don't want to have to rotate standard
out, do I? The logs can go in their home directory and count against their
storage, if that is how they want to play it.

I can rotate by restarting the server every once in a while, I guess.

Or do I want to make it easy? I'm not sure.

### Tue May 24 12:57:13 CDT 2011

Maybe everyone runs in the same control group? That way, people can pay for a
single account, and run multiple applications on the account, but those
applicatoins are all limited in their own way, but the price is that set price,
$0.01 instance hour. This gives people a way to be all in with Puppy, for the
cost of hosting their own application..

### Sat May 14 23:14:59 CDT 2011

PostregreSQL porting and pooling.

Nice [jump start](http://library.linode.com/databases/postgresql/fedora-14) at
Linode which is where you learn how to [set the
password](http://library.linode.com/databases/postgresql/fedora-14).

When I [revoke public
connect](http://developer.postgresql.org/pgdocs/postgres/sql-grant.html), do I
effectively prevent access to all objects in database except for those who are
expclicitly allowed to conect?
[pg_hba.conf](http://developer.postgresql.org/pgdocs/postgres/auth-pg-hba-conf.html)
is where authorization begins. We can prevent password prompt using the
`~/.pgpass` file. Their may be a way to prevent new databases from being public
at the outset using [default
privileges](http://developer.postgresql.org/pgdocs/postgres/sql-alterdefaultprivileges.html).
[Public Schemas in
SQL](http://stackoverflow.com/questions/2134574/public-schemas-in-postgresql).
More on [schemas](http://sql-info.de/postgresql/schemas.html), there is a public
schema created by default, but I suppose they expect you to tuck all objects in
a schema if you're super serious about PostregreSQL.

I can't make an in depth PostgreSQL security a pre-requistite of further work on
the port from MySQL, so I'll circle back on the research and develop a plan for
security before public beta.

Here's a discussion of [preventing default
allow](http://postgresql.1045698.n5.nabble.com/Re-help-with-pg-hba-conf-td2154145.html)
using revoke connect. A [critical
look](http://www.depesz.com/index.php/2007/10/04/ident/) at pg_hba.conf.
The [Practical PostgreSQL](http://www.commandprompt.com/ppbook/book1) book.
There are also some more recent books in Safari Bookshelf.

The documentation itself calls functions and triggers a [trojan
horse](http://www.postgresql.org/docs/8.3/interactive/perm-functions.html).

The concept we'll use for durability is streaming replication with hot standby,
which will eventually be replaced with the synchorouns replication in 9.1, due
out in three or more months. I'm going to defer to pgpool to do balancing, and
I'm willing to accept the possible data loss that comes from the streaming lag.

The documentation of [hot
standby](http://www.postgresql.org/docs/9.0/static/hot-standby.html) and the
9.1 documentation of [hot
standby](http://developer.postgresql.org/pgdocs/postgres/hot-standby.html).
PostgreSQL wiki entry on [streaming
replication](http://wiki.postgresql.org/wiki/Streaming_Replication) and
[hot standby](http://wiki.postgresql.org/wiki/Hot_Standby).
[pgpool II
tutorial](http://pgpool.projects.postgresql.org/pgpool-II/doc/tutorial-en.html).
A deck of slides on [pgpool II and streaming
replication](http://www.sraoss.co.jp/event_seminar/2010/20100702-03char10.pdf).
A blog post on [pgpool II and streaming
replication](http://blog.jagiello.org/2008/07/postgresql-pgpool-replication-mode.html)
and
[another](http://pgpool.projects.postgresql.org/contrib_docs/simple_sr_setting/index.html).

In order to allow one password to manage all PostgreSQL data, we're going to
have to put the same password for the same user on all PostgreSQL databases.

Converting MySQL.

PostgreSQL user defined functions to replace [MySQL
functions](http://okbob.blogspot.com/2009/08/mysql-functions-for-postgresql.html).
Some converstion pointers are in the [FAQ](http://wiki.postgresql.org/wiki/FAQ).
The [example table of different
types](http://blogs.sitepoint.com/site-mysql-postgresql-1/) is useful as a point
of reference. 

Systemd

 * [Why?](http://0pointer.de/blog/projects/why.html)
 * [The New Configuration Files](http://0pointer.de/blog/projects/the-new-configuration-files.html).
 * [Blame Game](http://0pointer.de/blog/projects/blame-game.html).
 * [Verifying Bootup](http://0pointer.de/blog/projects/systemd-for-admins-1.html).
 * [Which service owns proceses?](http://0pointer.de/blog/projects/systemd-for-admins-2.html).
 * [How to create a service](http://0pointer.de/blog/projects/systemd-for-admins-3.html).
 * [Killing services](http://0pointer.de/blog/projects/systemd-for-admins-4.html).
 * [Three Levels of Off](http://0pointer.de/blog/projects/three-levels-of-off.html).
 * [systemd.service](http://0pointer.de/public/systemd-man/systemd.service.html).
 * [systemd.exec](http://0pointer.de/public/systemd-man/systemd.exec.html).
 * [Changing Roots](http://0pointer.de/blog/projects/changing-roots).
 * [LSB](http://refspecs.freestandards.org/LSB_2.1.0/LSB-generic/LSB-generic/initscrcomconv.html).

### Sat May 14 21:53:57 CDT 2011

Next decision, which I'm pulling forward, is DRBD or GlusterFS. This is
difficult because there are other options, but they do not have cloud chatter. I
can't find a discussion about [Global File
System](https://forums.aws.amazon.com/message.jspa?messageID=49521), except to
hear that it requires special hardware. Coda seems to have
[stalled](http://www.coda.cs.cmu.edu/news.html).
[Ceph](http://ceph.newdream.net/) is the up and coming block store, but it is
not yet ready for production, still under heavy development.
[MooseFS](http://www.moosefs.org/) is current, but maybe too culstery, and
requires a [bullet-proof master](http://www.moosefs.org/reference-guide.html),
which acts as meta-data server.

Gluster FS looks [easy to
use](http://serverfault.com/questions/96001/mogilefs-glusterfs-etc-amazon-ebs-amazon-ec2).
One Drupal host has a nice list of crossed-out alternatives
(http://www.cloudave.com/21/acquia-uses-gluster-storage-for-drupal-gardens-saas-offering/)
including NFS. [DRBD](http://www.drbd.org/)  is not quite the same as Gluster
FS. It is more of a real time rsync to backup, 

This enter described why
[LVM is
useful](http://www.peakscale.com/archives/gridvm/drbd-lvm-gnbd-and-xen-for-free-and-reliable-san/).
Putting LVM on top of DRBD devices would make it easier to grow the devices as
need be, but we're going to develop a way to move programs around anyway.

> Linux Logical Volume Management (LVM) is a popular tool that lets you flexibly
> manage disk space. Instead of just partitioning the disk, using LVM lets us do
> on-the-fly logical partition resizing, snapshots (including hosting
> snapshot+diffs), and adding more physical disks into the volume group as needs
> grow (you can even resize a logical partition across multiple underlying
> disks).  Each logical partition is formatted with a filesystem of its own.
> Using LVM avoided some future headaches I think.

Here's a link to a [complicated Google
Doc](http://www.oreillynet.com/xml/blog/2008/05/awsec2_preparing_for_ec2_persi.html)
that I'm not going to read.

You can profile the performance of your disks using
[Bonie++](http://www.coker.com.au/bonnie++/). [IOzone](http://www.iozone.org/),
for example [ZFS v VxFS -
IOzone](http://blogs.oracle.com/dom/entry/zfs_v_vxfs_iozone)
[A new utility for quickly interpreting multiple Bonnie++ benchmarks](http://www.linux.com/archive/feature/139743). There is also
[filebench](http://www.cuddletech.com/blog/pivot/entry.php?id=949). You can
create a nice articel that is a shootout between the two solutions.  [A new
utility for quickly interpreting multiple Bonnie++
benchmarks](http://www.linux.com/archive/feature/139743). [Using Bonnie++ for
filesystem performance
benchmarking](http://www.linux.com/archive/feature/139742).

[Storge in the Cloud](http://cloudarchitect.posterous.com/glusterfs) gives a
GlusterFS rationale.
[glfs vs. unfsd performance
figures](http://lists.gnu.org/archive/html/gluster-devel/2010-01/msg00046.html).
[Gluster, the Red Hat of
Storage](http://www.voicesofit.com/blogs/blog1.php/2009/12/29/gluster-the-red-hat-of-storage).
[Playing with NFS & GlusterFS on Amazon cc1.4xlarge EC2 instance
types](http://blog.bioteam.net/2010/07/playing-with-nfs-glusterfs-on-amazon-cc1-4xlarge-ec2-instance-types/).
[Tuning glusterfs for apache on
EC2](http://www.sirgroane.net/2010/03/tuning-glusterfs-for-apache-on-ec2/).
[Glusterfs Distributed File System on Amazon
EC2](http://www.sirgroane.net/2010/03/distributed-file-system-on-amazon-ec2/).
[Early GlusterFS on
EC2](https://forums.aws.amazon.com/message.jspa?messageID=52873) disucssion.

http://mtocker.livejournal.com/38087.html
http://fghaas.wordpress.com/2007/08/07/configuring-heartbeat-links/
http://www.linuxfoundation.org/collaborate/workgroups/networking/bonding

[MySQL Replication vs DRBD
Battles](http://www.mysqlperformanceblog.com/2008/04/28/mysql-replication-vs-drbd-battles/),
[DRBD and MySQL: Just Say Yes](http://fghaas.wordpress.com/2008/04/27/drbd-and-mysql-just-say-yes/)

http://support.rightscale.com/09-Clouds/AWS/02-Amazon_EC2/Designing_Failover_Architectures_on_EC2/03-Advanced_Failover_Architecture
http://support.rightscale.com/09-Clouds/AWS/02-Amazon_EC2/Designing_Failover_Architectures_on_EC2/00-Best_Practices_for_using_Elastic_IPs_(EIP)_and_Availability_Zones
http://support.rightscale.com/09-Clouds/AWS/02-Amazon_EC2/Designing_Failover_Architectures_on_EC2/02-How_to_set_up_an_Intermediate_Failover_Architecture
http://support.rightscale.com/09-Clouds/AWS/02-Amazon_EC2/Designing_Failover_Architectures_on_EC2/01-How_to_set_up_a_Basic_Failover_Architecture
http://support.rightscale.com/09-Clouds/AWS/02-Amazon_EC2/Designing_Failover_Architectures_on_EC2/00-Best_Practices_for_using_Elastic_IPs_(EIP)_and_Availability_Zones
http://support.rightscale.com/2._References/02-Cloud_Infrastructures/01-Amazon_Web_Services_(AWS)/02-Amazon_EC2/Designing_Failover_Architectures_on_EC2
https://forums.aws.amazon.com/thread.jspa?messageID=112816

### Fri May 13 01:17:47 CDT 2011

Getting ready to move to PostgreSQL. Reading some Sherlock Holmes, which, one my 
mind was off the matter at hand, I realized that I'd fallen in favor of 
PostgreSQL by reading a [post on EBS 
replication](http://archives.postgresql.org/pgsql-general/2009-10/msg01214.php), 
where the following was said:

> As long as EBS snapshots are atomic (which I think they are, but don't know
> for sure), you can just do the snapshot, no need to do anything extra.
> PostgreSQL will then go into normal crash recovery when you start up another
> instance on the snapshot.

This appealed to me because it spoke to my understanding of PostgreSQL. It
goosed a memory of reading about PostgreSQL's MVCC implementation, back when I
was attempting to understand how atomicity worked in databases in general.

Suddenly, I'm reassured. Yes, I'll have to rewrite everything that I've created
recently in PostgreSQL, which is difficult because I am in no way database
agnositc. Quite nostic, acutually, but all that I've forgotten about PostgreSQL
pales in comparison to how little anyone knows about MySQL.

I'm not convinced that PostgreSQL is more durable that MySQL, but I do believe
there are good answers to questions about backup, if not replication. There are
people working to create answers to replication, in the form of the fast moving
pgpool, whose documentation is thin, but no thinner that the documentation on
MySQL-MMM, or [MySQL
Proxy](http://www.oreillynet.com/pub/a/databases/2007/07/12/getting-started-with-mysql-proxy.html).

MySQL-MMM wants to bind to bogus IPs. It may be possible in EC2, but it is not
obvious to me how to do it. It will be some time before I understand how the
network in EC2 works. If it were post based, I could defer that learning. Ports
may be an option in MySQL-MMM, but that is not obvious.

MySQL Proxy still claims to be alpha and amounts to writing proxy filters in
Lua, which I do not want to have to learn.

Thus, PostgreSQL is there and it anyway feels more open source. I've found the
[statistics
available](http://www.postgresql.org/docs/8.3/static/monitoring-stats.html) and
they appear to be row and file block statistics per table, which can easily
translate to per user account.

Then there is just the confidence the community has about their point in time
recovery. They just wave away concerns toward the point in time recovery, but it
means that the community is generally ready to discuss recovery, while the MySQL
community seems more oriented toward discussing HELP!! how do I create a table
for an Internet shopping chart?!?! HELP!

There are very smart guys doing very enterprise things in a very open source way
at Percona, but I've learned from the Linux guys that patched distributions are
a sadness. Do I want to maintain a custom built patched database? If PostgreSQL
has it all in the core, then I can install from the Fedora distribution.

The MySQL community is fragmented, with MySQL discussions taking place
everwhere, and the meaningful bits of conversation taking place on Percona.
There is probably hostility toward many questions, in the way that pedants
overrun communities and drive out experts. The intelligence of PostgreSQL is
available via their listserv.

Finally, I don't like to consider two difference database engines, nor do I want
to test two different database engines, InnoDB and MyISAM. MySQL is two
databases in itself. I'm going to worry about whether or not does full text or
geo effect backups in MySQL, but I won't worry about it in PostgreSQL.

Also, once people turn on
[InnoDB](http://wiki.postgresql.org/wiki/Why_PostgreSQL_Instead_of_MySQL_2009)
they fallback to a worse PostgreSQL. The speed advantage comes from MyISAM.

I'm still unsure about
[incremental backups of
InnoDB](http://www.mysqlperformanceblog.com/2008/11/10/thoughs-on-innodb-incremental-backups/)
and don't feel good at all that the only real solution is in Lauchpad by
Percona, instead of in [MySQL
itself](http://dev.mysql.com/doc/refman/5.1/en/backup-methods.html).

Might need to use [XFS to
snapshot](https://forums.aws.amazon.com/message.jspa?messageID=109005). You can
use this article [Running MySQL on Amazon EC2 with EBS (Elastic Block
Store)](http://aws.amazon.com/articles/1663?_encoding=UTF8&jiveRedirect=1) as a
reference. Found it via a
[PostgreSQL](http://stackoverflow.com/questions/2997969/postgresql-and-amazon-ebs-snapshots)
question on StackOverflow. Exciting [backup stuff using software RAID
0](http://blog.endpoint.com/2010/02/postgresql-ec2-ebs-raid0-snapshot.html) and
more evidence that PostgreSQL will do the right thing. The model for consistent
backups is [Creating Consistent EBS Snapshots with MySQL and XFS on
EC2](http://alestic.com/2009/09/ec2-consistent-snapshot). It seems that [XFS is
necessary](https://forums.aws.amazon.com/thread.jspa?messageID=208283). But,
[maybe not, maybe
LVM](http://serverfault.com/questions/192099/should-use-ext4-or-xfs-to-be-able-to-sync-backup-to-s3)
can make snapshots work. The [XFS FAQ](http://xfs.org/index.php/XFS_FAQ).

I've revisited the [Ma.gnolia
collapse](http://www.wired.com/epicenter/2009/01/magnolia-suffer/) by actually
[watching Chris Messina grin and rub his hands
together](http://vimeo.com/3205188). Searching for MySQL corruption detection
didn't produce much. Searching for PostgreSQL corruption detection produced the
[familiar sanguine
responses](http://archives.postgresql.org/pgsql-general/2009-04/msg01030.php).
Also found another [sad
story](http://techcrunch.com/2009/01/03/journalspace-drama-all-data-lost-without-backup-company-deadpooled/),
this about a malicious sysadmin.

Wow, stubmled upon [What’s wrong with
MMM](http://www.xaprb.com/blog/2011/05/04/whats-wrong-with-mmm/)? Which is moot,
because I've made up my mind, so I'm probably seeking reinforcement, but hey, I
wasn't looking for this. The article
[How PostgreSQL protects against partial page writes and data
corruption](http://www.xaprb.com/blog/2010/02/08/how-postgresql-protects-against-partial-page-writes-and-data-corruption/)
brought me to the site. The article on MMM is one of the recent article.
Enjoying this blog on inspection. The [next
gem](http://www.xaprb.com/blog/2011/04/25/the-bigger-they-are-the-harder-they-fall/)
is:

> With economies of scale come failures at scale. You can’t have it both ways.

Again, I'm not trying to build a system that will survive a nuclear attack, or a
system that can host real time applications, like ambulance dispatch, but
instead a place to build online stores, media offerings, communities. Things
that can survive a digital brownout. No SLA.

Some discussion of [RAID and
PostgreSQL](http://postgresql.1045698.n5.nabble.com/GENERAL-Disk-corruption-detection-td1862961.html)
with the quote:

> I'd argue that any raid controller that carries on without degrading the array
> even though it's getting write errors isn't worth the fiberglass the
> components are soldered to.

Trying to tame my inner child, who wants to accept the challenge of writing a
MySQL load balancer, consider that [Heroku won't have to do the
same](http://blog.heroku.com/archives/2010/7/20/nosql/):

> Of course, we can’t forget that Heroku currently runs the largest and most
> mature SQL-database-as-a-service in the world: our PostgreSQL service,
> packaged with every Heroku app.

More on the [Heroku
reasoning](http://www.quora.com/Heroku/What-were-the-reasons-for-Heroku-choosing-PostgreSQL-over-MySQL)
for PostgreSQL. Contrast to the MySQL reasoning for
[Quora](http://www.quora.com/Why-doesnt-Quora-use-PostgreSQL). Plus, Heroku has
a [MySQL offering](http://xeround.com/) that is suspiciously not
[RDS](http://www.quora.com/Is-Amazon-RDS-relational-database-service-good). Note
that [Heroku charges for backups](http://addons.heroku.com/pgbackups) of
PostgreSQL.PostgreSQL has [full text
search](http://tenderlovemaking.com/2009/10/17/full-text-search-on-heroku/). The
[PostgreSQL](http://devcenter.heroku.com/articles/database) documentation at
Heroku.

### Tue May 10 01:38:44 CDT 2011

Enable SELinux enforcing, touch `/.autorelabel` and reboot. You must set SELinux
enforcing or else SSH stops working.

Run `bin/bootstrap` to make sure you've got the latest and greatest. Make sure
that `alan` is in the `wheel` group.

Add `alan` to `wheel`.

Remove `sendmail`.

Will build the Puppy dependencies on a an EBS volume and snapshot it. Start with
a Fedora 15, log in as alan, and puppify it. Do not actually install puppy.

Create an EBS volume on which to build your version of Node.js. Mount it on
mount and create `src`, `node` and `opt`. Create symlinks for `/opt` and
`/node`.

### Sun May  8 01:14:03 CDT 2011

Took in a lot of information in a short period of time. Currently, I'm looking
at how to deploy Puppy Fedora 15, including `systemd`. While a part of me
wonders if I'm not making a mistake by requiring that a Puppy daemon use file
descriptor 3 instead of listening to a port. This can be put in the
configuration, and it can be documented, but it might confuse or upset
developers.

It makes my life easier, I hope. I'm not interested in a lot of opinion, though.
There is a right way to do this, and `systemd` does this the right way. It will
make process monitoring so much easier.

Well, arguments with the inner troll have really moved me away from where I want
to be. Creating something like the Law of Demeter site would be a good exercise.
Also, maybe adding trolls to the narrative, talking about them, how they work,
and how to get around them, that is an advantage.

<br>

It's so competitive. I'm looking at cari.net prices for RAID. 75 USD for 2 TB.
Three disks is 225 USD, RAID 1 with a hot backup. 

Ah, but people [do lose EBS
volumes](https://forums.aws.amazon.com/thread.jspa?threadID=46277). [Hardware
problems do occur](http://alestic.com/2011/02/ec2-move-hardware) at Amazon. Look
for stories of [EBS
corruption](http://www.google.com/search?sourceid=chrome&ie=UTF-8&q=ebs+volume+corrupt).
Sometimes all you have to to is
[restart](http://alestic.com/2011/02/ec2-move-hardware), but that's not
reassuring. Here's a place to [start reading about the judgement
day](http://www.elasticvapor.com/2010/05/failure-as-service.html). EBS versus
[RAID](https://forums.aws.amazon.com/thread.jspa?threadID=37676). EBS [mount
failure](https://forums.aws.amazon.com/thread.jspa?threadID=53485). EBS [failure
semantics](https://forums.aws.amazon.com/thread.jspa?threadID=24067). Another
organization that [survived judgement
day](http://blog.xeround.com/2011/05/xeround-and-the-amazon-ec2-outage-on-resiliency-high-availability-and-other-beasts),
not just Netflix. Also,
[SmugMug](http://don.blogs.smugmug.com/2011/04/24/how-smugmug-survived-the-amazonpocalypse/)
but they had no EBS usage.

[Joyent](http://joyeur.com/2011/04/24/magical-block-store-when-abstractions-fail-us/)
doens't believe in block storage.

Backblaze has a lot of [great
content](http://blog.backblaze.com/2011/05/03/backblaze-the-babysitter/) on
storage, and if storage mattered, I could build one of their Pods. Here's the
[downside](http://www.c0t0d0s0.org/archives/5899-Some-perspective-to-this-DIY-storage-server-mentioned-at-Storagemojo.html)
of the pod, which is not [terribly
down](http://www.c0t0d0s0.org/archives/5906-Thoughts-about-this-DIY-Thumper-and-storage-in-general.html).
Here's the first [not Backblaze Pod](http://extrememediaservers.blogspot.com/).


They could
easily [backup
Twitter](http://blog.backblaze.com/2011/03/23/5-years-of-twitter-in-13rd-a-backblaze-pod/).
They have
[grown](http://blog.backblaze.com/2011/01/05/10-petabytes-visualized/) to [100
pods](http://blog.backblaze.com/2010/06/14/backblaze-racks-100th-storage-pod/).
They got [great
press](http://blog.backblaze.com/2009/09/25/fallout-of-the-backblaze-storage-pod-post/)
for releasing their Pod, so how do I tell a story that people want to hear? They
[share their failures](http://blog.backblaze.com/2010/10/21/backblaze-presenting-at-failcon-10/)
in
[money](http://blog.backblaze.com/2010/08/27/backblaze-online-backup-almost-acquired-breaking-down-the-breakup/)
and
[maintainence](http://blog.backblaze.com/2010/09/28/scheduled-maintenance-lessons-learned/)
and [buttons](http://blog.backblaze.com/2010/04/23/dont-push-that-button/).


They have articles to story on
[broadband](http://blog.backblaze.com/2010/08/18/broadband-speeds-lies-and-statistics/),
the
[cloud](http://blog.backblaze.com/2010/06/30/gigaom-structure-2010-cloud-computing-event-summary/)
the
[yottobyte](http://blog.backblaze.com/2009/11/12/nsa-might-want-some-backblaze-pods/),

Differnet strategies for [Linux as
SAN](http://www.linuxjournal.com/magazine/use-linux-san-provider), including
[NFS](http://www.howtoforge.com/high_availability_nfs_drbd_heartbeat).

Need to learn about [LVM](http://tldp.org/HOWTO/LVM-HOWTO/anatomy.html) to get
something working on something else.

[DRDB](http://www.drbd.org/) is a SAN in the kernel. Here's [when to use
DRDB](http://fghaas.wordpress.com/2007/06/26/when-not-to-use-drbd/).

Trying to find someone who's used EBS with DRDB. There's a [nice description of
Netflix and
EBS](http://perfcap.blogspot.com/2011/03/understanding-and-using-amazon-ebs.html).
Here's the [offical message on Judgement
Day](http://aws.amazon.com/message/65648/).

http://www.quora.com/What-is-the-storage-used-by-Amazon-EBS
 * [What's the best choice for storage when running HDFS in the cloud: S3, EBS,
   or Instance Storage?](http://www.quora.com/HDFS/Whats-the-best-choice-for-storage-when-running-HDFS-in-the-cloud-S3-EBS-or-Instance-Storage)
 * [Why is storage purchased for your Google Account so much cheaper than Amazon
   S3?](http://www.quora.com/Why-is-storage-purchased-for-your-Google-Account-so-much-cheaper-than-Amazon-S3)
 * [Should I use Amazon S3 for personal data storage (photos, MP3s, etc)? If so,
   what's the best Mac client for
   S3?](http://www.quora.com/Amazon-S3/Should-I-use-Amazon-S3-for-personal-data-storage-photos-MP3s-etc-If-so-whats-the-best-Mac-client-for-S3).
 * [Which is a better solution for file storage, Amazon S3 or Rackspace Cloud
   Files?
   Why?](http://www.quora.com/Hosting-Providers/Which-is-a-better-solution-for-file-storage-Amazon-S3-or-Rackspace-Cloud-Files-Why).
 * [What is the average size of objects stored in Amazon S3 or Rackspace Cloud
   Files?](http://www.quora.com/Cloud-Storage/What-is-the-average-size-of-objects-stored-in-Amazon-S3-or-Rackspace-Cloud-Files).
 * [Does Quora use slaves for MySQL though the data is stored in Amazon's EBS
   (which already has replication since it is reliable)?](http://www.quora.com/Does-Quora-use-slaves-for-MySQL-though-the-data-is-stored-in-Amazons-EBS-which-already-has-replication-since-it-is-reliable).
 * [Does the data store layer for Quora run on
   EC2?](http://www.quora.com/Does-the-data-store-layer-for-Quora-run-on-EC2).

[Configuring Heartbeat
links](http://fghaas.wordpress.com/2007/08/07/configuring-heartbeat-links/).
[Split Brain](http://wiki.linux-ha.org/SplitBrain).

Hey, this [looks
easy](https://forums.aws.amazon.com/message.jspa?messageID=228613): [Gluster
FS on Amazon EC2](http://cloudarchitect.posterous.com/glusterfs-on-amazon-ec2-part-2).

The [Storage Mojo EBS post
mortem](http://storagemojo.com/2011/04/29/amazons-ebs-outage/), and post-mortems
from [Heroku](http://status.heroku.com/incident/151),
[Scalr](http://blog.scalr.net/tips/using-scalr-to-avoid-future-amazon-problems-surviving-az-outages/),
[Whiskey
Media](http://www.whiskeymedia.com/news/postmortem-whiskey-downtime-due-to-amazon-web-services-failure/13/),
[Chris
Moyer](http://blog.coredumped.org/2011/04/post-mortem-of-ebs-outage.html),
[Alestic](http://alestic.com/2011/04/ec2-outage),
[InformationWeek](http://www.informationweek.com/news/cloud-computing/infrastructure/229402534) and
[Amazon](http://aws.amazon.com/message/65648/) itself.
 
### Sat May  7 13:04:08 CDT 2011

How does [I/O limiting](http://www.linode.com/wiki/index.php/Swappiness) effect
Puppy? How do you [protected against
limiting](http://www.cyberciti.biz/faq/throttle-disk-io-rate-limit-disk-io/)? 

You will use [control
groups](http://www.novell.com/connectionmagazine/2010/09/effective_linux_resource_management_one.html)
to manage user processes. How do you manage MySQL processes?

It seems that you can get disk I/O stats from Percona. However it is done, it
can be patched into MongoDB. My strategy will be to measure transfer and
queries, plus I/O if I can. Let's see what MySQL can do.

Tell people how bills are based. Let them inspect the system sources where their
bills come from.

Maybe you can just inject some profiling using [System
Tap](http://www.mysqlperformanceblog.com/2009/09/14/systemtap-dtrace-for-linux/).
More examples of [System Tap and I/O](http://glandium.org/blog/?p=1476).

Some nicely formatted general articles on [Disk
I/O](http://blog.scoutapp.com/articles/2011/02/10/understanding-disk-i-o-when-should-you-be-worried)
and [I/O performance
analysis](http://www.cmdln.org/2010/04/22/analyzing-io-performance-in-linux/).

Don't forget [RDDTool](http://oss.oetiker.ch/rrdtool/). You'll have to find some
way to grow your storage over time. More [ways to profile
MySQL](http://stackoverflow.com/questions/618997/what-is-the-best-way-to-diagnose-and-profile-mysql-in-live-production-server).

This looks to be the way in which [I/O is accounted in
EC2](http://www.ghidinelli.com/2009/05/26/estimating-io-requests-ec2-ebs-costs).
[Software RAID using
EC2](http://af-design.com/blog/2010/03/02/honesty-box-ebs-performance-revisited/).

[Kernel control
groups](http://doc.opensuse.org/products/draft/SLES/SLES-tuning_draft/cha.tuning.cgroups.html)
used by systemd and how to [use
them](http://www.novell.com/connectionmagazine/2010/09/effective_linux_resource_management_one.html).

As long as the ratio of rows affected to blocks written is relatively constant,
then I'll be able to cover my costs. I can look at graphs to see if someone is
eating away at profits, maybe doing a lot of writing by having really large
binaries.

[View I/O
operations](http://www.xaprb.com/blog/2009/01/13/iopp-a-tool-to-print-io-operations-per-process/).

### Fri May  6 15:53:03 CDT 2011

Mind is starting to bend around some of the issues involved here, so I need to
switch so some form of learning.

What does that number in a DNS record? &mdash; It is a [specific TTL for the
record](http://www.zytrax.com/books/dns/apa/ttl.html) that overrides the default
for the zone file.

We can run DNS on our Amazon servers. It will be part of the overhead for
running the infrastructure.

But, I'm coming up with prices for everything else.

How do I create my own StrongSwan VPN on EC2? &mdash; It appears that I have to
move from transport to tunnel, and then they are going to ping each other to
keep the NAT open. Maybe with Amazon VPC I can get an IP address directly bound
to a machine.

What was the purpose of Strongswan? &mdash; Primarily the notion that one could
build a scalable application with many node instances, that people could
experiment with scale in that way. I could create firewall rules on the machines
that limit which machines can talk to each other, or I could explore the idea of
assigning port numbers to applications, maybe by clumping up users in some way.

If Shorewall is capable of uninterruped reloads, I can filter connections within
the VPN using Shorewall, adding allow rules off of a tree based on the local
subnet, but the user has to request it, so that we don't pay for all this
filtering unless we need it. As they do, I allocate one of the ports that has
already been opened up in SELinux.

We are probably way ahead of ourselves, though. The only application for this is
micro-sharing, which will be cheap anyways.

Stop having arguments with your inner troll. Yes, someone is going to tell me
about the wonders of open source.

Wait. Now I'm thinking that Linode is not such a bad thing. What is that about?
&mdash; It comes down to making Linode durable, I believe. The community is
smaller. The costs are fixed. Charging for bandwidth will pay for the server, if
I can commit all the bandwidth. I make money off bandwidth at the outset.

Need to learn how to automate the failover. 

Can we failover to Amazon for the duration of an upgrade? &mdash; People who
expect many nodes to be on the same network will be surprised. I can offer
Amazon EC2 hosting or Linode hosting.

<br>

MySQL Proxy continues to be an alpha release after three years. It was
interesting, in that it can analyze queries, so that it can do read/write splits
during load balancing. I found [an example of
this](http://jan.kneschke.de/projects/mysql/mysql-proxy-learns-r-w-splitting)
and it turns out that the analisys amounts to sipping the query body for the
word "SELECT". Huh. So, I can just write a MySQL proxy in CoffeeScript once
Packet MySQL driver is complete.

[MySQL Proxy was
discussed](http://dev.mysql.com/tech-resources/articles/failover-strategy-part3.html)
in a three part series on replication and failover at the MySQL blog. This
series was tl;dr, but I should, since it has a nice play by play of failover,
showing how much data is lost.

What to do in the meantime, because I can't move forward on Puppy development
with the legacy I've already created. I have two or more applications that need
MySQL. 

The [different forms of replication for
MySQL](http://www.mysqlperformanceblog.com/2009/11/13/finding-your-mysql-high-availability-solution-%E2%80%93-replication/)
at the Percona blog. After a lot of reading, it leads me to believe that
[MMM](http://mysql-mmm.org/) is the only application layer solution. I'm not in
a position to build a SAN or deploy [DRDB](http://www.drbd.org/). The first
article I encountered talked about how to [keep the replicant
hot](http://www.mysqlperformanceblog.com/2009/02/01/fast-mysql-master-master-failover-with-select-mirroring/),
but really, at this point, I just want to be able to take down one of my Linodes
long enough for maintainence. I'd use [MMM](http://mysql-mmm.org/mysql-mmm.html)
version 2.

But, it needs more IP addresses than I have to offer. It seems to confusing.
Maybe maatkit will allow me to do what I need to do.

Here's an
[HAProxy](http://www.alexwilliams.ca/blog/2009/08/10/using-haproxy-for-mysql-failover-and-redundancy/index.html#mysqlchk_status)
solution.

There is mention of, but no examples using, [maatkit](http://www.maatkit.org/).
Oh, [here's a
mention](http://blog.mysql-mmm.org/2009/08/verify-master-master-slave-data-consistency-between-masters-without-locking-or-downtime/).

So, to offer MySQL, the only real solution is a huge honking write database,
master-master. Currently, I can implement this with a minimal MMM setup, which
may or may not scale, I'm not sure. In the long run, I'm not sure I want to
support TB sized MySQL databases. That's what's been bothering me today. The
nice Percona aricle gives me something to point to and say, I did option B, and
you can see for yourself the ramifications.

Yet, I'm sure there are going to be a lot of projects where someone wants to
spring an application from the clutches of Rails of PHP and bring it over to
Node.js, but they are bound to a MySQL database. This is the Adva use case.

So, if you have a web store, or a blahg, or something, use MySQL. If you need to
scale, then use MongoDB or PostgreSQL.

When time comes, I could write a hot little MySQL proxy in Packet to show how
hot Packet is. For the glory I could go as far as to parse the statement. 

 * [SQL Parsers for
   Java](http://stackoverflow.com/questions/660609/sql-parser-library-for-java)
   and [Zql](http://www.gibello.com/code/zql/).
 * [SQL::Statement](http://search.cpan.org/~rehsack/SQL-Statement-1.33/lib/SQL/Parser.pm)
   in Perl.
 * [SQL Parser in Python](http://code.google.com/p/python-sqlparse/) and a
   [discussion at Stack
   Overflow](http://stackoverflow.com/questions/1394998/parsing-sql-with-python),
   [Gadfly](http://gadfly.sourceforge.net/) a relational database in Python, and
   a two part series on parsing SQL in Python: [Part
   1](http://andialbrecht.wordpress.com/2009/03/29/sql-parsing-with-python-pt-i/),
   [Part
   2](http://andialbrecht.wordpress.com/2009/03/29/sql-parsing-with-python-pt-ii/).
 * [BNF Grammars](http://savage.net.au/SQL/).
 * [JS/CC](http://jscc.jmksf.com/) a JavaScript compiler compiler.
 * [Python full text search](http://whoosh.ca/).

Note that [databases from Amazon are expensive](http://aws.amazon.com/rds/pricing/).

PostgreSQL [looks
easier](http://scale-out-blog.blogspot.com/2009/02/simple-ha-with-postgresql-point-in-time.html).
[Pools are easier](http://pgpool.projects.postgresql.org/).

### Sun Apr  3 13:28:16 CDT 2011

What are the security implementations of when you `ssh` to a server?

I am liking the idea of offering IPSEC connection to Puppy.

<hr>

Seems like I'm much faster now, here on UNIX, in CoffeeScript. Faster than I was
in Ruby even, in the same place.

But, it is the distance from Java. I'm admiring my little server restart script,
that rings the bell no less, to let me know that things have changed. It is
impressive, this start script, kind of, but simple, and it was something I built
in the course of building Done Did It. Now I have it, and I'm bringing it to
other projects as I use it. It is gets more features as I use it in the
wrinkledog Scheduler.

With Java this would never be. I was struggling to make Java work on the command
line, and like all things Java, it would never be as good as the thing under its
many layers of abstraction. So, I wouldn't stop and say, no let's make that
better, because evertime I said that, it would mean another Ant file.

### Fri Apr  1 13:55:17 CDT 2011

Funny how I'm embrancing SQL, but at the same time embracing CoffeeScript.

### Sun Mar 27 14:50:30 CDT 2011

The default node path puts `/opt/lib/node` at the end, so all scripts will
attempt to read the home directory when looking for a library installed with
`npm`. I want the path to have both the Puppy and npm installed libraries at the
top of the list.

I went looking for a way to do this, to pass down an environment variable
through `sudo` and quickly realized that if it was possible to do this, then any
user could inject code by replacing the `common/public` library with an
implementation of their own.

Which means that, at this point, node is searching home directories for
libraries to include. This gets fixed if I can change the `NODE_PATH`, so that
the search of the home directories gets short-circuited when the libraries are
found. Their is no way to tell the program to look for more libraries. The user
has to replace `common/public` or `mysql`, one of the libraries that Puppy
depends upon.

SELinux would have caught any attempts to do anything more than read and write
to the database, but, hey, that's game over for Puppy anyway.

Running as root, I was able to use the -E switch and inherit an environment, but
running as worker I'm not. You must add `SETENV` along with `NOPASSWD` to a
user or group sudoer configuration.

    [worker@dvor ~]$ NODE_PATH=/tmp/common sudo -Eu system /puppy/system/bin/user_ready
    sudo: sorry, you are not allowed to preserve the environment

I found `env_file` in sudoers and created one adding the `NODE_PATH`. Then I
turned off `env_keep` and turned on `always_set_home`. Now `sudo` programs will
get a bare environment. Note that I could put the `HOSTNAME` in `env_keep`, but
that would mean configuring it twice for the machine, so I'm going to require
programs to continue to execute `/bin/hostname`.

Note that the `sudoers` fields `log_input` and `log_output` are interesting.

<hr>

I do not have time to think about it tonight, by Ryan says that Node.js is
moving away from POSIX and toward handles, so that Node.js becomes ever more
like Java.

This is disappointing. I was enjoying the tight binding to POSIX. Now we're
going to have objects again, and we're going to have less Linux goodness, more
of jittery cross-platformedness. If we're moving to abstractions of that sort,
why not just use Haskell?

Although, it would keep me in JavaScript, and CoffeeScript, but it would also
move me away from what I thought was the ideal.

How do you react to this? You cannot politic to enforce a world of you own. This
is a community that defers to Ryan on all matters. If it goes the way of Java,
so it goes. If there is a way to keep it POSIX, while permitting this departure,
great, but if not, you need to find a new language.

You're getting so much done with Node.js, it would be such a pity to move to
some new language that you don't want to understand. Maybe you need to use
Google V8 yourself, learn how it works and work with it directly, on all your
projects. Maybe you need to learn to use something that is an alternative. 

Maybe you need to use Perl to build your Linux applications. Need to put this
aside, but wait, I have invested a lot of time on a project here. Shouldn't I
respond to this potential change? If it is going to change, I ought ot drive
this change. The only way to do that is to cut code.

But, if I cut cude, then I'm doing something for them that is not worth it for
me to do. Or do I do this so I can build Synapse?

Probably need to stick with the Haskell plan. Also, probably read to look at
supporting different agents in Puppy. That way, it is not just a Node.js
application. I can make it available to Haskell, Python, and Node.js.

<br>

Because the programs that use the try/catch wrapper are all protected, you may
want to name the wrapper `_try` and call it. Then the log will reflect which are
the programs, with `worker`, and which are wrappers, like `worker_try`.

This means that we need to change up the install, to install the `_try` suffixed
programs without the suffix, but that is very confusing, or create a try file
that lists the programs that need wrappers.

### Sat Mar 26 02:29:38 CDT 2011

Locked down `/dev/log` by telling rsyslog to create it in `/dev/loggers/log` and
making `/dev/loggers` owned by `root:loggers` with mode `750`. All users who
have a UID of 700 or less are members of `loggers`. It would appear that
`unbound`, `auditd` and `postfix` are all logging fine.

I created an `auditd` rule that reports on all failures of the system call
`socketcall`. It took a while to sort out how to create the rule and interpret
the output. At first I was attempting to find failed `open` system calls, but
that's not the right system call for sockets. (I guess not everything is always
a file in UNIX.)

Using `logger a`, I didn't get any error messages. However, `echo a > /dev/log`
did produce error messages, so I was confused.

Reading through the source code of the `logger` utility, found in `util-linux`,
and `syslog`, found in `glibc`, I could see that the path `/dev/log` was the
only way in which the system log was addressed. Still, attempting to watch
`/dev/log` or look for `open` in the `/dev` directory failed to produce error
messages.

I tried to log all system calls for my user id. That created a lot of spew. Then
I limited it to failed system calls. That was a bit more reasonable. When I
wrote to the log using a C program consisting of function cut and paste from
logger, I saw some errors. 

Using a [Linux Syscall Reference](http://syscalls.kernelgrok.com/) it didn't
take long to figure out the call to sort out was 102, socketcall. This was a
three line message, first a line of type `SYSCALL`, then `SOCKETCALL`, then
`SOCKETADDR`. With some of the C source rattling around my brain, I could see
that part of the `saddr` value was a hex encoded zero terminated ASCII string
that started with `/d`, so I figured that's my socket name.

I adjusted my rule to detect all failed socketcall calls system wide. I wrote
some CoffeeScript to slurp the file and read that string, filtering from the
audit log failed attempts to connect to `/dev/log`.

Note that, in my muddled mind, I before parsing I thought something came after
the socket path in that saddr dump, because it was 220 characters long and the
`sockaddr_un` was a [short and 108 character
buffer](http://www.gnu.org/s/libc/manual/html_node/Local-Namespace-Details.html).
After I got it working, I set out to parse the rest and quickly realized that
220 / 2 = 2 + 108, so the saddr was all there and only two fields as in the
documentation. I find it interesting that I didn't put this together the first
time it revolved. 

Note too that, this may be a different system call on the 64 bit architecture, so
you may have to change this auditing if you move to the fatter Linux.

Now I have a script that does on thing, and I can see that there is no daemon
failing to log its activity at the moment, but how do I detect this in the
future. I've determined that this is something I want to watch, so how do I
watch it?

Beginning to consider the structure of system monitoring. This would be part
RRT, showing performance, and part monitoring. Moitoring would gathering
information from logs, confirming assertions about the systems behavior.

Questions that arise during development would be expressed as monitoring, such
as, are there any daemons that are unable to log to the relocated `/dev/log`.

Also starting to consider how to advertise the project. It is so simple, I do
want people to try a full featured version, but limit them so that they don't
blow my budget. I need support to develop the application, so their may be no
free rides, but one thought would be to limit the number of sessions

This would run through yet another proxy that would count the open sessions, and
if there are too many, sessions open for the host, the user gets a strange
message, like maximum session limit reached, please upgrade to a full Puppy
account. This session counter would go after virtual hosts and before the Puppy
node. The session counter lives as a process on the same machine as the node.

Beginning applications are not going to be load balanced, so there is only one
place to go after virtual hosts. There is only one place to go anyway, since
virtual hosts does not do load balancing.

Upcoming is further configuration of
[auditd](http://people.redhat.com/sgrubb/audit/) and an evaluation of
[acct](http://www.gnu.org/software/acct/). The home pages for these projects did
not Google well.

Did you *read* the man page? If it is in man page, you won't find it on Google.
Others will have read the man page, they won't ask questions. You can search
Google for a question, but not an understanding.

I couldn't get the addition groups right in `bin/puppify` using:

    /usr/sbin/usermod -G $group $user

I'd look at `/etc/group` and the `common` group would be empty. Oh, my!
`usermod` must be broken!

Yet, when I read the manpage, I see that -G sets a set of groups, comma
deliminted and if the user is a member of a group not in the list, then the user
is removed from the group. So my Puppy agent users were removed from `common`
when they were added to `loggers`.

But, if I add `-a` it does what I expect.

You can safely assume that the Linux and GNU utilities are not broken. There is
little on them in Google because the people who use them read man pages.

<hr>

Maybe it makes sense to have the log analysis for a particular user on the
client side, have them download all the records.

Was thinking about my table structure, and how to search logs, when a record
may or may not be there, and what if a user does a DoS attack by sending an
awful query, which would be possible. Do I timeout? Can I timeout? Probably yes,
but I could send the records to an HTML 5 SQL database and have them search.

But, now I relalize, they aren't going to be searching that particular database,
that is only for my usage.

<hr>

You can find the different flags for the first argument to socketcall in
`/usr/include/linux/net.h`.

Tried to see what sort of errors were generated by `worker`, so I added this
rule.

    sudo auditctl -a exit,always -S all -F uid=worker -F success=0 -k WORKER

Running worker for a while does produce errors. I took the time to understand
what they meant. Here is some notion of the output of auditd.

    type=SYSCALL msg=audit(1301166263.070:63339): arch=40000003 syscall=102 success=no exit=-115 a0=3 a1=bf90b740 a2=1 a3=0 items=0 ppid=15332 pid=15334 auid=4294967295 uid=204 gid=204 euid=204 suid=204 fsuid=204 egid=204 sgid=204 fsgid=204 tty=(none) ses=4294967295 comm="node" exe="/opt/bin/node" subj=system_u:system_r:worker_t:s0 key="WORKER"
    type=SOCKETCALL msg=audit(1301166263.070:63339): nargs=3 a0=7 a1=856baec a2=10
    type=SOCKADDR msg=audit(1301166263.070:63339): saddr=02000CEA7F0000010000000000000000

This confused me because I spend a lot of time looking at the second line, which
I believed where the arguments to socket call. The first argument, `7`, maps to
to `getpeername`.

The exit value is the [errno
negated](http://osdir.com/ml/linux.redhat.security.audit/2008-05/msg00042.html).
According to `/usr/include/asm-generic/errno.h `, `115` maps to `EINPROGRESS`.
The man page for `getpeername` does not list `EINPROGRESS` as a possible return
value.

After some time spent digging through the source for `audit`, finding nothing
new to consider. I read through the `node` source and saw that the only calls to
`getpeername` throw an exception if they return anything other than success.
Seemed unlikly that the `node-mysql` would trigger this exception, catch it and
continue, which is the only way to explain how `getpeername` was showing up in
`audit.log` as a failure.

I came back to the message itself and read each field in the `type=SYSCALL` line
and saw `a0=3`. `3` maps to `connect`, which is something that `node-mysql`
definately does do, and the return code `EINPROGRESS` indicates that an
asynchronous call has been made, but is not yet ready.

Thus, the real call here is `connect` and the error is benign. What then are the
arguments on the `type=SOCKETCALL` line. Turns out they are the arguments to
`connect`, the `7` being a file descriptor. When the `glibc` implementation
`connect` for x86 Linux is called, [its arguments are put into an
array](http://jkukunas.phpnet.us/2010/05/23/x86-linux-networking-system-calls-socketcall/),
and then the sytem call `socketcall` is made.

That explains what's going on in the syslog message.

The return code for this message, is a total mystery.

    type=SYSCALL msg=audit(1301174240.456:68050): arch=40000003 syscall=192    success=no exit=-1264771072 a0=0 a1=1000 a2=3 a3=22 items=0 ppid=15332 pid=15334 auid=4294967295 uid=204 gid=204 euid=204 suid=204 fsuid=204 egid=204 sgid=204 fsgid=204 tty=(none) ses=4294967295 comm="node"exe="/opt/bin/node" subj=system_u:system_r:worker_t:s0 key="WORKER"

Since `192` apparently maps to `lgetxattr` according to audit, but I can't find
a reference to `192` in glibc. The source is in the `attr` source package on
Fedora.

Now I've downloaded the kernel, and for x86, the `192` syscall is `mmap2`, which
is a version of `mmap` that uses 4k blocks for offsets instead of bytes, to
allow mapping large files. The system call occurs with each call.

Now I've fetched [an mmap
example](http://www.linuxquestions.org/questions/programming-9/mmap-tutorial-c-c-511265/)
from the Internet, compiled it and ran it as `alan`, with the same `auditctl`
filter that I'm running for `worker`. I added a `printf` to display the `int`
value of the successful `mmap` call. The `int` value printed to the console also
appears exit field value of a `192` syscall.

Thus, the pointer value returned by `mmap` has its highest order bit set, which
makes the value negative, but its really a pointer. None the less, the audit
logic in the kernel sees a negative value and marks the syscall as a failed
call, so it gets reported as a failed call.

Imperect. There's not good way to filter out successful or unsuccessful `mmap`
calls with the current tools. `auditctl` would need to filter out a range.

This is enough `audit.log` exploration. I've got a pretty good understanding now
of how the syscall code is structured, though I don't understand all of how it
works. I'm sure syscall itself is written in assmebly, so that will be
impossible for me to read right now.

I now have a patch that I can write and submit to the kernel.

<hr>

Late night now. I'm not sure how I got into it, but I began researching dtrace,
since I'd become convinced it was very important at some point in the past.

There is a nice thread on [DTrace in a mailing list for a Linux
conference](https://lists.linux-foundation.org/pipermail/ksummit-2008-discuss/2008-June/000149.html)
where one of the developers from Red Hat chimes in amidst the brouhaha and
encourages [usage and
feedback](https://lists.linux-foundation.org/pipermail/ksummit-2008-discuss/2008-June/000158.html).
Doesn't Linux have a clearer path forward than the forked OpenSolaris project
[Illumos](http://www.illumos.org/)?

Systemtap appears to be read for prime time. It is a Fedora package. It's easy
enough for me to install and go. If I can get it to behave with SELinux, this
could be a logging facility I could make available to Puppy users.

I'm feeling good about Systemtap and Linux. Look at what Brian and Ryan were
doing at Joyent made feel foolish, but Brian's bombast must stem from the
reality that the work would be copied elsewhere, or, you know, pride.

Kind of marketing FUD. I like Red Hat. I hope they do well. They are a sutble
company. Ubuntu stealing all their thunder, but they have a great distribution.

Maybe. I don't really know what I'm talking about. Ubuntu looks like Craftsman
and Red Hat looks like Snap On. Ubuntu is really just for single user systems,
web hosting. That they make the home directories default world readable is
astounding.

### Tue Mar 22 02:14:07 CDT 2011

Found out that my mail client has not been upgraded to work with Node.js v0.4.x.
The library configuration is wrong for the latest NPM, the NPM without shims.
After adjusting the path, I find that SSL is broken.

While I still plan on patching it, I'd like to take this opportunity to deploy
Postfix, with these requirements.

 * Authorization is required to send mail.
 * Local users cannot invoke `sendmail` or otherwise queue mail from the comand
   line.
 * No delivery of mail to local users.

The primary purpose of this Postfix server is to pull email out of the Puppy
work queue and put it in a local mail queue. We don't want the Puppy queue to
hang on a remote SMTP request or abend when it doesn't get the response it
expects. Mail is a robust protocol.

Failed submissions ought to go to some sort of a dead letter file. How to you
reject mail? Where should it go?  [http://www.postfix.org/postconf.5.html#maximal_queue_lifetime](http://www.postfix.org/postconf.5.html#maximal_queue_lifetime)
Does it get returned to sender?

There is no recipe for the following. I have a working recipe to send to gmail
that is much simpiler than the top hit for the search on Google. It must be
based off of [Relaying Postfix SMTP via smtp.gmail.com](http://ubuntu-tutorials.com/2008/11/11/relaying-postfix-smtp-via-smtpgmailcom/)
because it is essentially the same.

Ultimately, I'd like to have a real email gateway. When I do, I'll want it to
treat the host Postfix as a feeder. When I do this, I'll implement [address
masquerading](http://www.postfix.org/ADDRESS_REWRITING_README.html#masquerade)
to make email appear to come from the gateway and bounce to the gateway.

Like logging, which I struggled with the last two days, disabling email from the
shell is surpisingly easy. Simply:

    chmod o-x /usr/sbin/postdrop

That ought to put an end to email from local users. I'm hoping that SMTP still
works, but I've not gotten there yet.

Failure messages appear in the messages inbox in GMail, marked as failures.

You must install `cyrus-sasl-plain` for the GMail relay to work.

I've decided not provide users with email and will myself use msmtp to send
email, at least to try it for a while, see if it is available on FreeBSD.

### Mon Mar 21 12:41:42 CDT 2011


Spent the weekend rewriting Puppy on the server side. Breaking out the `private`
into `private` and `system`.

The `system` branch will be for utilities called by `worker` jobs. The `private`
branch will be invoked by `public`, `liminal` or `protected`.

The split means simplifying the definition of the utilities. The utilities will
only ever update the database, maybe run `/bin/hostname`. Utilities need the
host name for most queries, but `system` utilities are always passed the host
name from the `worker` job program. They never write to the console as I'd once
thought they might.

Thus, the definition for all utilities for a module is the same. This means
creating a macro and listing the utilities in the `private` or `system` module.

The utilities invoked by the user are grouped by the user role. There is a
`private_public_t`, `private_liminal_t` and `private_protected_t`. The utilties
that a user role can run are labeled with the the private type context for that
role. A role can invoke any utility, there is no transition script.

Unlike the user roles, the `worker` role has type contexts for each job program.
The job program can only invoke specific `system` utilities. The `system`
utilities are labeled with a type context derived from the utilitiy name.

Conceptually, there is a set of system altering utilities for each mutative
agent. The system alterations are always initiated by an update to the MySQL
database that defines the system. A mutative agent is an agent that has the
ability to alter the file system itself, such as a worker job or a user logged
in in a particular role.

Recent physical changes include...

 * That split of `private` into `system`.
 * Renaming the previous `system` branch to `janitor`, which mean renaming the
   previous `janitor` branch to `system`. (I don't have that many names.) The
   `janitor` is the semi-automated, semi-human role that maintains the system.
 * Renaming `createDatabase` to `createSystem` and mushing up things into a
   `System` object, since `Database` is a misnomer.
 * Added a script, `bin/fcgen` to generate the type contexts. Now that the new
   NPM links into the library, the paths have gotten to long and dotted to write
   in by hand.
 * Created `bin/tail.coffee` which tails the message log and formats entires
   created by Puppy. 
 * Created a try/catch strategy, where errors are caught and logged, for
   user roles, so that thrown errors to not leak to the user's console,
   potentialy revealing passwords and such.
 * Using exceptoins and fail fast now, due to `bin/tail.coffee` and its
   ability to display nested exceptions.
