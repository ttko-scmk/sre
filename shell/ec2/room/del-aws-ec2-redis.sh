#!/bin/sh
set -e
v=$1

#exp
#sh del-aws-ec2-redis.sh 10.2.208.10

EC2_ID=`aws ec2 describe-instances --filters "Name=private-ip-address,Values=$v" --query "Reservations[0].Instances[0].InstanceId" --output text`
aws ec2 terminate-instances --instance-ids "$EC2_ID" > /dev/null 2>&1
