#!/bin/bash
set -e
v=$1
p=$2
i=$3

#exp
#sh del-rds-slave.sh scmk001-slave01 ap-east-1

aws rds delete-db-instance --db-instance-identifier "$v" --region "$p" > /dev/null 2>&1

#刪除cloudwatch
aws cloudwatch delete-alarms --alarm-names "$v-CPU平均使用率大於75%" "$v-連線數大於500" --region "$p"
