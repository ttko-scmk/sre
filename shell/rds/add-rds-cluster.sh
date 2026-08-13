#!/bin/bash
set -e
v=$1
p=$2
i=$3
#exp
#sh add-rds-cluster.sh scmk02-live ap-east-1
aws rds create-db-cluster  --db-cluster-identifier "$v"  --engine aurora-mysql --engine-version 8.0.mysql_aurora.3.10.3  --master-username scmk_user --master-user-password 9faaec527d4d45c29f121230e17945f18d1a9567 --serverless-v2-scaling-configuration MinCapacity=0.5,MaxCapacity=30  --db-subnet-group-name scmk-1010  --vpc-security-group-ids sg-016425fbf3bb8ff74  --region "$p" --storage-encrypted > /dev/null 2>&1
sleep 60
aws rds create-db-instance --db-cluster-identifier "$v" --db-instance-identifier "$v"-cluster --engine aurora-mysql --db-instance-class db.serverless --storage-encrypted > /dev/null 2>&1
