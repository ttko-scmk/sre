#!/bin/sh

set -e
v=$1

#exp
#sh del-nginx-80p.sh scmk

ssh 10.8.217.207 "rm -rf /usr/local/nginx/conf/vhosts/"$v"*"
ssh 10.8.217.207 'nginx -t'
ssh 10.8.217.207 'nginx -s reload'
sleep 3
ssh 10.8.229.5 "rm -rf /usr/local/nginx/conf/vhosts/"$v"*"
ssh 10.8.229.5 'nginx -t'
ssh 10.8.229.5 'nginx -s reload'
sleep 3
ssh 10.8.243.6 "rm -rf /usr/local/nginx/conf/vhosts/"$v"*"
ssh 10.8.243.6 'nginx -t'
ssh 10.8.243.6 'nginx -s reload'
sleep 3
