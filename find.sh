#!/usr/bin/env bash
aws ec2 describe-security-groups --query 'SecurityGroups[*].GroupId' --output text | tr '\t' '\n' | sort -u > sg.txt

aws ec2 describe-instances --query 'Reservations[*].Instances[*].SecurityGroups[*].GroupId' --output text | tr '\t' '\n' | sort -u > instance.txt

aws elb describe-load-balancers --query 'LoadBalancerDescriptions[*].SecurityGroups' --output text | tr '\t' '\n' | sort -u > elb.txt

aws ec2 describe-network-interfaces --query NetworkInterfaces[*].Groups[*].GroupId --output text | tr '\t' '\n' | sort -u > eni.txt 

# find SGs that aren't part of a stack
for i in `cat sg.txt` ; do aws ec2 describe-security-groups --group-ids $i --query 'SecurityGroups[*].Tags[*]'> /tmp/sg-tags-$i ; if [ $? == 1 ]; then break; fi ; if grep -q 'aws:cloudformation:stack-name' /tmp/sg-tags-$i; then echo "$i has a cf stack" 1>&2; echo $i; fi; rm /tmp/sg-tags-$i; done | sort -u > stack-sgs.txt

cat instance.txt elb.txt eni.txt stack-sgs.txt  | sort -u > used-sgs.txt

comm -23 sg.txt used-sgs.txt > unused-sg.txt

# for i in `cat unused-sg.txt `; do echo $i; aws ec2 delete-security-group --group-id $i; done
