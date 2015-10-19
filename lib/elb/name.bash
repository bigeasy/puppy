
#!/bin/bash

set -e

puppy module <<-usage
    usage: puppy elb name

    description:
        Get the DNS name of the ELB.
usage

aws elb describe-load-balancers --region="$puppy_region" | \
    jq -r '.LoadBalancerDescriptions[] | select(.LoadBalancerName == "puppy-balancer") | .DNSName '
