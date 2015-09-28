# Puppy

This is a project that I'd been working on in my own time, to create a scalable
hosting environment for Node.js that can be deployed to EC2.

One thing that I loved about Node.js when I adopted it was that it starts small;
a small web program will only take a small amount of memory, unlike some other
web platforms where you need to ante up 512MB before you can play.

Knowing that for small programs Node.js has a small memory footprint, it lead me
to believe that Node.js could compete with PHP for the class of applications
where PHP still dominates MVC frameworks; content applications. These are
applications like shopping carts, blogs, forums, etc. For these applications, a
developer would want PHP style hosting; multi-tenant hosting for low-memory
applications, whose content can swap out of memory, bringing down the cost.

Node.js can scale up like Ruby on Rails, but couldn't also scale down like PHP?

I've pulled this from the more recent diary:

Puppy is based on these assumptions.

 * **Evented I/O** will greatly reduce the CPU and memory load for hosting over
   the last fashion wave of Ruby on Rails and J2EE before that.
 * By returning to multi-tenant hosting, and taking advantage of Linux control
   groups, in lieu of virtualization, resources can be flexibly allocated to the
   customer processes that need it most. This is the finance of computing. It
   will be cost advantage. I'll have spare resources for visualization and
   monitoring.
 * The **security threat of multi-tenant hosting is mitigated by SELinux** and
   mandatory access control. The security model for any object is expressed
   twice, first using discretionary access control, via UNIX permissions and
   iptables, chroot, then again using SELinux policies.
 * Template based solutions are the best solution for a majority of
   applications, so a **structured, evented template language is superior to
   MVC**, and worth the complexity costs of building tag libraries, which are
   conceptually more difficult than models and controllers, but simpler on the
   other side of the learning curve.
 * Pricing is set by a markup on **Amazon EC2** which will always have the
   **lowest price for scalable resources**. Amazon EC2 costs reflect the real
   costs of hosting. There is a $30 dead zone that is not worth filling, after
   the price is noticeable, before it is comparable to the people who offer a
   chunk of free transfer.
 * Organic growth is possible by selling at the outset and dwindling the
   reserve, using the up front to pay Amazon. Customers must consume the
   capacity that they reserve, so there is no turning off and on the control
   group you hire, because I can't afford to keep a computer around for you to
   use if you choose to use it.

This was the idea behind a hosting service I could bootstrap.

However, I don't want to start a business. I want to write code. You are all
lovely people, but you can be real babies when it comes to things like hosting.
I'd rather have you as collaborators than customers.

Also, as an open source project, I'm going to make it focused. I've found
through my Timezone project that simply stating at the outset that you're not
going to be all things to all people attracts people who want that in a project.
I'd been afraid to open source this project because I imagined it would only
attract entitlement; it's not supposed to be another Linux distribution, but
rather a quick way to get your Node.js hosting going.

Right now, this project is *not working*, but I've had it working in theory with
failover for web hosting and database. I need to reconstruct it as program you
pull down from NPM and get going.

I've become a more focused developer since I began. As I pursue this project as
an open source project, I'm going to focus on the EC2 platform to the exclusion
of other platforms. This means that I'll probably migrate away from using
PostgreSQL as a datastore, instead adopting one of the AWS datastores.

Read my stream of conciousness in my
[diary](https://github.com/bigeasy/puppy/blob/master/diary.md) and my [old
diary](https://github.com/bigeasy/puppy/blob/master/diary-old.md).
