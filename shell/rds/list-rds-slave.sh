#!/bin/bash
set -e
v=$1
p=$2
i=$3

#exp
#sh list-rds-slave.sh zjinhui001-slave01 ap-east-1
aws rds describe-db-instances --db-instance-identifier "$v" --region "$p" --query "DBInstances[0].Endpoint.Address" --output text
