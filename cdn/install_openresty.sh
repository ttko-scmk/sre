#!/usr/bin/env bash
set -e

echo "=== 1. 基礎安裝與更新 ==="
dnf install -y epel-release
dnf update -y
dnf install -y jq wget zip net-tools tar logrotate yum-utils

dnf config-manager --add-repo https://openresty.org/package/rhel/openresty.repo
dnf install openresty-1.31.1.1-1.el9 --nogpgcheck -y

echo "=== 2. 系統優化 ==="
timedatectl set-timezone Asia/Taipei
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
setenforce 0 || true

echo "=== 3. 優化 SSH ==="
sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config
sed -i 's/#GSSAPIAuthentication yes/GSSAPIAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/PubkeyAuthentication no/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart sshd

echo "=== 4. 增加進程與文件開啟數量限制 ==="
if ! grep -q "soft nofile 65536" /etc/security/limits.conf; then
    cat << 'EOF' >> /etc/security/limits.conf
* soft nofile 65536
* hard nofile 65536
* soft nproc 65536
* hard nproc 65536
EOF
fi

echo "=== 5. 設定軟連結與目錄準備 ==="
rm -f /usr/bin/nginx /usr/sbin/nginx
ln -s /usr/local/openresty/nginx/sbin/nginx /usr/bin/nginx
ln -s /usr/local/openresty/nginx/sbin/nginx /usr/sbin/nginx

# 建立相關設定目錄
mkdir -p /usr/local/openresty/nginx/conf/vhosts
mkdir -p /usr/local/openresty/nginx/conf/ssl
mkdir -p /usr/local/openresty/nginx/logs

echo "=== 6. 部署 SSL 憑證 ==="
cat << 'EOF' > /usr/local/openresty/nginx/conf/ssl/ca.key
-----BEGIN PRIVATE KEY-----
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
cMwyvzJG+B87W4x2yGEZtoLO2iMWeg==
-----END PRIVATE KEY-----
EOF

cat << 'EOF' > /usr/local/openresty/nginx/conf/ssl/ca.pem
-----BEGIN CERTIFICATE-----
MIIFnTCCA4WgAwIBAgIUdXIddp08fPOOEfPqYu6+ktUez6MwDQYJKoZIhvcNAQEN
BQAwXjELMAkGA1UEBhMCVFcxDzANBgNVBAgMBlRhaXBlaTEPMA0GA1UEBwwGVGFp
cGVpMQ0wCwYDVQQKDAR0ZXN0MQwwCgYDVQQLDANsYWIxEDAOBgNVBAMMB2V4YW1w
bGUwHhcNMjMwNzE3MDMxODMwWhcNMzMwNzE0MDMxODMwWjBeMQswCQYDVQQGEwJU
VzEPMA0GA1UECAwGVGFpcGVpMQ8wDQYDVQQHDAZUYWlwZWkxDTALBgNVBAoMBHRl
c3QxDDAKBgNVBAsMA2xhYjEQMA4GA1UEAwwHZXhhbXBsZTCCAiIwDQYJKoZIhvcN
AQEBBQADggIPADCCAgoCggIBAKF+iB6Kjj9ZrVXjydHFnayCx0NmxduhmoH1ZSPJ
4DE73C71nH5FvdwdBY81KYvbmmXt+Fu4CozBoFeSMgP+R8+ZzdJZbHQsShLVZrqx
qibpOaIXAIE3FYsUEoZHe/E995ooyp7EXH/iSgCioWLNRAH6lKHk7cuvVclmTMBj
qCd1UPY2Jh9MCYLWNvgWl308C43xDFCWqB2CycCs0p1KMtjBUoXAqMrSPcUxU5ue
LHb5KYnXWsLKskWd91PuM4XSNilOhvlDL31wZKJSQaTrlFStybGtpybBZ3j0CFxf
3h4xsri6AAiLwENuoxy4iXLg3KorKQhelFm6oYj/OtxKCiEKjqAcENuIotw8hn5o
jin+Sb4ewR9xlUd8br4cpIPOubtkCypsU9Cia1n71YQ5vZFRGCgq5fMYIsIyuIbl
MrC3+Ri/p+4RNo/20PtEPuJyPxOy5HBU9BJ2ulia5bynbwFOC7sjXswLdIBCrx0P
PI3TmkWbID11n4ZY9SQ81qzQgTFX2N75pSbHeRqPi/38veWPlqpXXBFEv6zZPydp
ulMRAPiALMnSbE6v7NxqhVsuLVVoIkV2cAspcJa2NxIMeHdFbZcrZ9yBb9U7yBw5
rXrtl4Fdev3IbGDl3Ov61RIcXF3UAYeu6iQvq6q3NSJWi4ITZoJkgVY8ijxwV4XB
eQjTAgMBAAGjUzBRMB0GA1UdDgQWBBTktd/CstYpJ2ykZegOKVjppPvMojAfBgNV
HSMEGDAWgBTktd/CstYpJ2ykZegOKVjppPvMojAPBgNVHRMBAf8EBTADAQH/MA0G
CSqGSIb3DQEBDQUAA4ICAQCKuqnEzATN8Uah4Jn+vSdEMEMOdPjU1m61Moz7c/C/
sI1Kfzwa/0Ubbs1OR0x0bqz2K6Gwe6VwKJ9DybFUh7SmBnt6gwt4cxRdM7EHMTZV
9ofTMC8zvlNN/3g4yqtA80JIp7ZyVH5O//6dc5rc/C3EdUrKtmKb/TSlTqMA06S8
YqgqhVVKLu1pDixtLBHMJOB+7pNmU6QFA+9vsxfQqfNBeuogZik7DVTHtA6GmFZC
EIxetEZ57InyU4talCzHsenkbm15MhZDvsEuS1Q1pZmwxbu/Uu7+AxYpB8oReAM6
nGPxwHf+z2Ypx/rAIwx/zCp81DCujx8CtrKA1CxVl2Mdp2VVznUeInVKZ6cL5xmG
/AyLcqiOUE8dt43SkCzMeNeQu91LfcRUJ1jinHDygpLjm8HanL2CroSr54BG+2lc
JbBcNLCfml/yge4LfvVr8URmdodEzyIE9bdDIfkyWWZ8heyY17l433w9HxcL4UEp
N5QyDSiLjJtnAEAa87xuaa4wpeTEMgIIfspjh3tkWRp3xZ6TC9E1sJS3kiEvPmWo
0MCAPuSsaRwEPvpkj+mKkG0rY1JwXMd9X8fOTUHrcz7zTdrEX69KxECXI6RllTDs
OMvEwEgXS7YDx7HlvJ2UHQraKmJW4fjN/w+wkm//4iEvnwptbFx0Uw84V4bwNEji
rw==
-----END CERTIFICATE-----
EOF

chmod 600 /usr/local/openresty/nginx/conf/ssl/ca.key
chmod 644 /usr/local/openresty/nginx/conf/ssl/ca.pem

echo "=== 7. 覆寫 nginx.conf 主設定 ==="
cat << 'EOF' > /usr/local/openresty/nginx/conf/nginx.conf
user  root;
worker_processes  auto;
worker_rlimit_nofile 100000;

events {
    worker_connections  65535;
}

http {
    include       mime.types;
    default_type  application/octet-stream;
    server_names_hash_bucket_size 256;
    limit_req_zone $binary_remote_addr zone=one:10m rate=3000r/m;
    
    map $http_upgrade $connection_upgrade {
        default upgrade;
        '' close;
    }

    log_format main '{'
        '"msec": "$msec", '
        '"connection": "$connection", '
        '"connection_requests": "$connection_requests", '
        '"pid": "$pid", '
        '"request_id": "$request_id", '
        '"request_length": $request_length, '
        '"remote_addr": "$remote_addr", '
        '"remote_user": "$remote_user", '
        '"remote_port": "$remote_port", '
        '"time_local": "$time_local", '
        '"time_iso8601": "$time_iso8601", '
        '"request": "$request", '
        '"request_uri": "$request_uri", '
        '"args": "$args", '
        '"size": $body_bytes_sent,'
        '"status": "$status", '
        '"body_bytes_sent": $body_bytes_sent, '
        '"bytes_sent": $bytes_sent, '
        '"http_referer": "$http_referer", '
        '"http_user_agent": "$http_user_agent", '
        '"http_x_forwarded_for": "$http_x_forwarded_for", '
        '"http_host": "$http_host", '
        '"server_name": "$server_name", '
        '"request_time": "$request_time", '
        '"upstream": "$upstream_addr", '
        '"upstream_connect_time": "$upstream_connect_time", '
        '"upstream_header_time": "$upstream_header_time", '
        '"upstream_response_time": "$upstream_response_time", '
        '"upstream_response_length": "$upstream_response_length", '
        '"upstream_cache_status": "$upstream_cache_status", '
        '"upstream_status": "$upstream_status", '
        '"ssl_protocol": "$ssl_protocol", '
        '"ssl_cipher": "$ssl_cipher", '
        '"scheme": "$scheme", '
        '"request_method": "$request_method", '
        '"server_protocol": "$server_protocol", '
        '"domain": "$scheme://$server_name"'
    '}';

    sendfile        on;
    keepalive_timeout  65;

    gzip  on;
    gzip_min_length   1k;
    gzip_buffers      4 16k;
    gzip_http_version 1.0;
    gzip_comp_level   3;
    gzip_types        text/plain text/css application/x-javascript text/xml application/xml application/xml+rss text/javascript application/json;
    gzip_vary         on;

    proxy_http_version 1.1;
    proxy_set_header Connection "";

    include       vhosts/*.conf;
}
EOF

echo "=== 8. 部署 default.conf 預設站點 (相對路徑) ==="
cat << 'EOF' > /usr/local/openresty/nginx/conf/vhosts/default.conf
server {
    listen 80 default_server;
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;
    
    # 採用相對路徑 (相對於 /usr/local/openresty/nginx/)
    ssl_certificate     conf/ssl/ca.pem;
    ssl_certificate_key conf/ssl/ca.key;

    add_header Strict-Transport-Security "max-age=63072000; includeSubdomains;";

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_timeout 5m;
    ssl_session_cache shared:SSL:5m;

    server_name _;
    return 302 https://www.microsoft.com/;

    location ~ .*/(.svn)/.* {
        return 500;
    }

    location / {
        root   html;
        index  index.html index.htm;
    }

    location ~* ^.+\.(jpg|jpeg|gif|css|png|js|ico|html)$ {
        access_log        off;
        expires           24h;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   html;
    }
}
EOF

echo "=== 9. 配置 Logrotate 日誌切割 ==="
cat << 'EOF' > /etc/logrotate.d/openresty
/usr/local/openresty/nginx/logs/*.log {
    daily
    dateext
    dateformat -%Y-%m-%d
    missingok
    rotate 2
    compress
    delaycompress
    notifempty
    sharedscripts
    su root root
    postrotate
        if [ -f /usr/local/openresty/nginx/logs/nginx.pid ]; then
            kill -USR1 $(cat /usr/local/openresty/nginx/logs/nginx.pid)
        fi
    endscript
}
EOF

echo "=== 10. 建立 Systemd 開機自啟動服務 ==="
cat << 'EOF' > /usr/lib/systemd/system/openresty.service
[Unit]
Description=The OpenResty Application Server
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/usr/local/openresty/nginx/logs/nginx.pid
ExecStartPre=/usr/local/openresty/nginx/sbin/nginx -t
ExecStart=/usr/local/openresty/nginx/sbin/nginx
ExecReload=/usr/local/openresty/nginx/sbin/nginx -s reload
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

echo "=== 11. 新增運維管理帳號 (greed) ==="
if ! getent passwd greed > /dev/null; then
    useradd -r -m -s /bin/bash greed
fi

mkdir -p /home/greed/.ssh
if [ ! -f "/home/greed/.ssh/id_ed25519" ]; then
    ssh-keygen -t ed25519 -N "" -f /home/greed/.ssh/id_ed25519
fi

touch /home/greed/.ssh/authorized_keys
if ! grep -q "AAAAC3NzaC1lZDI1NTE5AAAAIDz4Dq2jIg3dtYGUfyIY4urXBkUiSMOgDGcib90jaObW" /home/greed/.ssh/authorized_keys; then
    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDz4Dq2jIg3dtYGUfyIY4urXBkUiSMOgDGcib90jaObW" >> /home/greed/.ssh/authorized_keys
fi

chmod 700 /home/greed/.ssh
chmod 600 /home/greed/.ssh/authorized_keys
chown -R greed:greed /home/greed/.ssh

if ! grep -q "greed" /etc/sudoers; then
    echo "greed    ALL=(ALL)        NOPASSWD: ALL" >> /etc/sudoers
fi

echo "=== 12. 測試配置並重載啟動服務 ==="
/usr/local/openresty/nginx/sbin/nginx -t

systemctl daemon-reload
systemctl enable openresty
systemctl restart openresty

echo "=== 安裝與設定完成 ==="
/usr/local/openresty/nginx/sbin/nginx -V
