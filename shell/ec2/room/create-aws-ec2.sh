#!/bin/sh
set -e
v=$1
p=$2
t=$3
h=$4

#exp
#sh create-aws-ec2.sh scmk-room-redis01 subnet-095e0f4b8feec9d9a 10.11.200.10 t4g.medium
#sh create-aws-ec2.sh scmk-room-redis01 subnet-0947d041b365536d9 10.11.208.10 t4g.medium
#sh create-aws-ec2.sh scmk-room-redis01 subnet-072ccb62c7f6cb53b 10.11.216.10 t4g.medium


#預約機器IP
#IP_ID=$(aws ec2 allocate-address --domain vpc  | jq -r '.AllocationId')
#aws ec2 create-tags --resources "$IP_ID" --tags Key=Name,Value="$v"-IP

#創建機器
EC2_ID=`aws ec2 run-instances --image-id ami-0f8de810a3582c405 --instance-type "$h" --key-name greed --subnet-id "$p" --security-group-ids sg-0f771fc24667a89ae --private-ip-address "$t" --query 'Instances[0].InstanceId' --output text`
#EC2_ID=`aws ec2 run-instances --image-id ami-00e9ad9848892d4dd --instance-type "$h" --key-name greed --subnet-id "$p" --security-group-ids sg-08b47300edf9ec608 --private-ip-address "$t" --query 'Instances[].InstanceId[]' | jq '.[]'  |  tr -d '"'`

#設標籤
aws ec2 create-tags --resources "$EC2_ID" --tags Key=Name,Value="$v"

#分配彈性IP
#IP=`aws ec2 associate-address --instance-id "$EC2_ID" --allocation-id "$IP_ID"`

#輸出對外IP
#aws ec2 describe-instances --filters Name=private-ip-address,Values="$t" --query 'Reservations[].Instances[].PublicIpAddress[]' | jq '.[]'  |  tr -d '"'
