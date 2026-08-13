#!/bin/sh

set -e
v=$1

#exp
#sh /data/ec2/room/del-nginx-80p.sh scmk

ssh 10.8.219.67 "rm -rf /usr/local/nginx/conf/vhosts/"$v"*"
ssh 10.8.219.67 'nginx -t'
ssh 10.8.219.67 'nginx -s reload'

ssh 10.8.225.193 "rm -rf /usr/local/nginx/conf/vhosts/"$v"*"
ssh 10.8.225.193 'nginx -t'
ssh 10.8.225.193 'nginx -s reload'
