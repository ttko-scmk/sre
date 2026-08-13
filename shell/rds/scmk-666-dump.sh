#!/bin/sh
set -e
v=$1
p=$2
#exp
#sh scmk-666-dump.sh cs06 

mysqldump -h scmk-666-master.cfwgoc26ygpd.ap-east-1.rds.amazonaws.com -u scmk_user -p15ef2e33783d4d575ded2cf1df82e933ccd64c69  init > /tmp/init.sql
mysql -h "$p" -u scmk_user -p15ef2e33783d4d575ded2cf1df82e933ccd64c69 -e "CREATE DATABASE $v"
mysql -h "$p" -u scmk_user -p15ef2e33783d4d575ded2cf1df82e933ccd64c69  "$v" < /tmp/init.sql

rm -rf /tmp/init.sql
