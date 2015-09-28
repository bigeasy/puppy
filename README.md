# Puppy

Create a Homeport container:

```
homeport --tag aws create
homeport --tag aws append \
    zsh vim git rsync \
    formula/pip:awscli \
    formula/chsh:alan,/usr/bin/zsh \
    formula/jq \
    formula/locale:en
```

Run the Homeport container and connect via SSH.

```
homeport --tag aws run
homeport --tag aws ssh
```
