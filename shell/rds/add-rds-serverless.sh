#!/bin/bash
set -e
v=$1
p=$2


#exp
#sh add-rds-serverless.sh scmk-666 scmk001-slave01 
aws rds create-db-instance --db-cluster-identifier "$v" --db-instance-identifier "$p" --db-instance-class db.serverless --engine aurora-mysql --no-auto-minor-version-upgrade --promotion-tier 10 --db-parameter-group-name ttkx-parameter-8 > /dev/null 2>&1
#aws rds describe-db-instances --db-instance-identifier "$v" --query "DBInstances[0].Endpoint.Address" --output text

#建CPU監控
#aws cloudwatch put-metric-alarm --alarm-name ""$p"-CPU平均使用率大於75%" --alarm-description "Alarm when CPU exceeds 75 percent" --metric-name CPUUtilization --namespace AWS/RDS --statistic Average --period 60 --threshold 75 --comparison-operator GreaterThanThreshold  --dimensions Name=DBInstanceIdentifier,Value="$p"  --evaluation-periods 1 --alarm-actions arn:aws:sns:ap-east-1:387125169234:Telegram --unit Percent

#建連線數監控
#aws cloudwatch put-metric-alarm --alarm-name ""$p"-連線數大於500" --alarm-description "Alarm DatabaseConnections above 500  " --metric-name  DatabaseConnections --namespace AWS/RDS --statistic Average --period 300 --threshold 500 --comparison-operator GreaterThanThreshold  --dimensions Name=DBInstanceIdentifier,Value="$p"  --evaluation-periods 1 --alarm-actions arn:aws:sns:ap-east-1:387125169234:Telegram --unit Count

