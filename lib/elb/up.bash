#!/bin/bash

set -e

puppy module <<-usage
    usage: puppy vpc create

    description:
        Create an AWS VPC.
usage

aws elb create-load-balancer \
    --load-balancer-name 'puppy-balancer' \
    --listeners 'Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80' \
    --subnets $(puppy_exec vpc subnet-id)

aws elb delete-load-balancer-listeners \
    --load-balancer-name 'puppy-balancer' \
    --load-balancer-ports 80
