#!/bin/sh
set -e
v=$1
p=$2
#exp
#sh scmk-1010-dump.sh cs06 scmk-live.cluster-crq0wu4woeyc.ap-east-1.rds.amazonaws.com

mysqldump -h scmk-live.cluster-cfwgoc26ygpd.ap-east-1.rds.amazonaws.com -u scmk_user -p9faaec527d4d45c29f121230e17945f18d1a9567  init > /tmp/init.sql
mysql -h "$p" -u scmk_user -p9faaec527d4d45c29f121230e17945f18d1a9567 -e "CREATE DATABASE $v"
mysql -h "$p" -u scmk_user -p9faaec527d4d45c29f121230e17945f18d1a9567  "$v" < /tmp/init.sql

rm -rf /tmp/init.sql
