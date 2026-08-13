#!/bin/sh
set -e
v=$1
p=$2
t=$3
h=$4

#exp
#sh create-aws-ec2.sh scmk-redis01 subnet-053a85bf3583f0a8f 10.9.200.10 c6g.large
#sh create-aws-ec2.sh scmk-redis01 subnet-03564925f3ed6b55f 10.9.208.10 c6g.large
#sh create-aws-ec2.sh scmk-redis01 subnet-0138f55b223dae649 10.9.216.10 c6g.large


#預約機器IP
#IP_ID=$(aws ec2 allocate-address --domain vpc  | jq -r '.AllocationId')
#aws ec2 create-tags --resources "$IP_ID" --tags Key=Name,Value="$v"-IP

#創建機器
EC2_ID=`aws ec2 run-instances --image-id ami-0f8de810a3582c405 --instance-type "$h" --key-name greed --subnet-id "$p" --security-group-ids sg-0b8ea1e53ad5d947e --private-ip-address "$t" --query 'Instances[0].InstanceId' --output text`
#EC2_ID=`aws ec2 run-instances --image-id ami-08fb1a36e9669c988 --instance-type "$h" --key-name greedyu --subnet-id "$p" --security-group-ids sg-02101d0d0044bb912 --private-ip-address "$t" --query 'Instances[].InstanceId[]' | jq '.[]'  |  tr -d '"'`

#設標籤
aws ec2 create-tags --resources "$EC2_ID" --tags Key=Name,Value="$v"

#分配彈性IP
#IP=`aws ec2 associate-address --instance-id "$EC2_ID" --allocation-id "$IP_ID"`

#輸出對外IP
#aws ec2 describe-instances --filters Name=private-ip-address,Values="$t" --query 'Reservations[].Instances[].PublicIpAddress[]' | jq '.[]'  |  tr -d '"'
