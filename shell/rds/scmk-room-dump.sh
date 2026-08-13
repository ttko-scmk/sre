#!/bin/sh
set -e
v=$1
p=$2
#exp
#sh scmk-1010-dump.sh cs06 scmk-live.cluster-crq0wu4woeyc.ap-east-1.rds.amazonaws.com

mysqldump -h scmk-room.cluster-cfwgoc26ygpd.ap-east-1.rds.amazonaws.com -u scmk_user -p0bbd40652416b05628587e9318542ecfec8b5747  init > /tmp/init.sql
mysql -h "$p" -u scmk_user -p0bbd40652416b05628587e9318542ecfec8b5747 -e "CREATE DATABASE $v"
mysql -h "$p" -u scmk_user -p0bbd40652416b05628587e9318542ecfec8b5747  "$v" < /tmp/init.sql

rm -rf /tmp/init.sql
