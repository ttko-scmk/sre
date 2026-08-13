#!/bin/sh

set -e
v=$1
pass=$2
b=$3
c=$4
#exp 專屬會員NG使用
#sh add-nginx-mp-80p.sh scmk-1mp.fbw3.net nlb-scmk-mnber-ng-87a4420d220f40f9.elb.ap-east-1.amazonaws.com nlb-scmk-portal-java-ae486c0512b72d79.elb.ap-east-1.amazonaws.com

echo 'upstream '$v' {
  server '$pass':80;
}
server {
  listen 80;  
  listen [::]:80;
  server_name '$v';
  add_header alt-svc '"'"'h3-27=":443"; ma=86400, h3-28=":443"; ma=86400, h3-29=":443"; ma=86400, h3=":443"; ma=86400'"'"';
  access_log /var/log/nginx/web_access.log main;
  error_log /var/log/nginx/web_error.log;

  location /
  {
    proxy_pass http://'$v';
  
    client_max_body_size 200M;
    
    #跨域CORS設定
    if ($request_method = 'OPTIONS') {
      add_header 'Access-Control-Allow-Origin' "$http_origin";
      add_header 'Access-Control-Allow-Methods' '*';
      add_header 'Access-Control-Allow-Headers' '*';
      add_header 'Access-Control-Allow-Credentials' 'true';
      add_header 'Access-Control-Max-Age' '86400';
      return 200;
      }

    #設定WebSocket,注意nginx.conf要補map設定
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;

    proxy_buffering off;
    proxy_buffer_size 8192k;
    proxy_buffers 4 8192k;
    proxy_redirect off;
    proxy_busy_buffers_size 16384k;  
    proxy_temp_file_write_size 16384k;
    proxy_hide_header  Vary;
    proxy_ignore_headers Cache-Control Expires;

    proxy_ssl_server_name on;
  
    proxy_ignore_client_abort on;
    proxy_connect_timeout 900;
    proxy_read_timeout 900;
    proxy_send_timeout 900;
    send_timeout 900;
    
    proxy_http_version 1.1;

    proxy_set_header Upgrade "$http_upgrade";
    proxy_set_header Host "$host";
    proxy_set_header X-Real-IP "$remote_addr";
    proxy_set_header Connection "'""'";
    proxy_set_header X-Forwarded-For "$proxy_add_x_forwarded_for";
    proxy_set_header X-Forwarded-Host "$host";
    proxy_set_header X-Forwarded-Server "$host";
    proxy_set_header proto-status "$scheme";
    proxy_set_header Cookie "$http_cookie";
    proxy_pass_header Set-Cookie;
    proxy_set_header   Accept-Encoding "'""'";
    proxy_set_header   Referer "$http_referer";

    proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 non_idempotent;

    proxy_ignore_headers Set-Cookie;
    include mime.types;
    default_type application/octet-stream;
  }
  
    location /api/
  {
    proxy_pass http://'$b'/;
    client_max_body_size 200M;
  }

} ' > /tmp/$v.conf

scp  /tmp/$v.conf 10.8.217.207:/usr/local/nginx/conf/vhosts/
scp  /tmp/$v.conf 10.8.229.5:/usr/local/nginx/conf/vhosts/
scp  /tmp/$v.conf 10.8.243.6:/usr/local/nginx/conf/vhosts/

ssh 10.8.217.207 'nginx -t'
ssh 10.8.217.207 'nginx -s reload'

ssh 10.8.229.5 'nginx -t'
ssh 10.8.229.5 'nginx -s reload'

ssh 10.8.243.6 'nginx -t'
ssh 10.8.243.6 'nginx -s reload'


rm -rf /tmp/*.conf
