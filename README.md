# Puppy

Create a Homeport container:

```console
$ homeport --tag aws create
$ homeport --tag aws append \
    zsh vim git rsync curl \
    formula/pip:awscli \
    formula/chsh:alan,/usr/bin/zsh \
    formula/jq \
    formula/locale:en
```

Run the Homeport container and connect via SSH.

```console
$ homeport --tag aws run
$ homeport --tag aws ssh
```

Clone Puppy.

```console
$ mkdir -p ~/git/docker
$ cd ~/git/docker
$ git clone git@github.com:bigeasy/puppy.git
```

Link puppy into your path.

```
$ cd ~/git/docker/puppy
$ puppy/link ~/.usr
$ which puppy
/home/alan/.usr/bin/puppy
$ ls -la $(which puppy)
lrwxrwxrwx 1 alan alan 38 Sep 28 05:38 /home/alan/.usr/bin/puppy -> /home/alan/git/docker/puppy/puppy.bash
```

Create a VPC.

```
$ puppy --tag puppy --region oregon vpc create
vpc vpc-43793426
internet_gateway vpc-43793426
subnet subnet-5cdf5505
route_table rtb-b31144d6
security_group sg-15c45471
```

Spawn some CoreOS instances.

```
$ puppy --tag puppy --region oregon coreos up --count 5
```

Create a load balancer to balance your instances.

```
$ puppy --tag puppy --region elb create
```

How does your application know about the load balancer? Not sure. I believe that
might be application level, or maybe there is some Puppy discovery.

<a name="study-vpcs"></a>
The VPC acts a little database for a particular application. Your VPC is where
you deploy CoreOS containers and whatever other images that need to participate
in your application. The VPC tags are used to store global information.

-    discovery: https://discovery.etcd.io/dfecd45b5cc972bf03190dd845b79af0
+    discovery: https://discovery.etcd.io/8dad394898a26f7ade14f00ec3b02901
homeport --tag aws append bsdmainutils

TODO: The subnet should be the place where the CoreOS material is kept.
