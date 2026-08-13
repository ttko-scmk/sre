#!/bin/sh

set -e
v=$1

#exp
#sh del-nginx-80p.sh scmk

ssh 10.8.221.196 "rm -rf /usr/local/nginx/conf/vhosts/"$v"*"
ssh 10.8.221.196 'nginx -t'
ssh 10.8.221.196 'nginx -s reload'

ssh 10.8.231.43 "rm -rf /usr/local/nginx/conf/vhosts/"$v"*"
ssh 10.8.231.43 'nginx -t'
ssh 10.8.231.43 'nginx -s reload'

ssh 10.8.244.234 "rm -rf /usr/local/nginx/conf/vhosts/"$v"*"
ssh 10.8.244.234 'nginx -t'
ssh 10.8.244.234 'nginx -s reload'
