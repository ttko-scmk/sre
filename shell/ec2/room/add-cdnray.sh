#!/bin/sh
set -e
v=$1
ip=$2

#EXP
#sh /data/ec2/room/add-cdnray.sh changjiang alb-yunduan-websocke-java-51678201.ap-east-1.elb.amazonaws.com

cdnray=`curl --request GET https://panel.cdnray.com:8443/accessToken --header 'SKC-RefreshToken: 51ebd34db8a0e5303628c8eb416a2941feafa8c08ed63a90e18db9cc072ce546' | jq ".accessToken" | sed 's/"//g'`

curl --request POST  --header 'Content-Type: application/json'  --header "SKC-RefreshToken: 51ebd34db8a0e5303628c8eb416a2941feafa8c08ed63a90e18db9cc072ce546"   --header "SKC-AccessToken: $cdnray" \
    --data '{
        "domains": [
            {
                "name": "'$v'-room-websocke.taidagediao.com",
                "scheme": 0,
                "autoSSL": false,
                "forceSSL": true,
                "portMap": false,
                "tags": [],
                "status": 1,
                "certificateID": 228682,
                "customHeaderModuleID": 0,
                "corsID": 132,
                "upstreams": [
                    {
                        "ip": "'$ip'",
                        "port": 80,
                        "weight": 1
                    }
                ]
            }
        ]
    }' \
    https://panel.cdnray.com:8443/api/v1/user/site/551/domains
