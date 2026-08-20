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

# 建立 vhosts 與日誌目錄
mkdir -p /usr/local/openresty/nginx/conf/vhosts
mkdir -p /usr/local/openresty/nginx/logs

echo "=== 6. 覆寫 nginx.conf ==="
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

echo "=== 7. 配置 OpenResty Logrotate 日誌切割 ==="
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

echo "=== 8. 建立 Systemd 開機自啟動服務 ==="
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

echo "=== 9. 新增運維管理帳號 (greed) ==="
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

echo "=== 10. 重載並啟動 OpenResty 服務 ==="
systemctl daemon-reload
systemctl enable openresty
systemctl restart openresty

echo "=== 安裝與設定完成 ==="
/usr/local/openresty/nginx/sbin/nginx -V
