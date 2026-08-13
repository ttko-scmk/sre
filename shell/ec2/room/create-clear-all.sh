#!/bin/sh
sleep 300
ssh root@10.8.219.67 'nginx -t' 2>&1
ssh root@10.8.219.67 'nginx -s reload' 2>&1
ssh root@10.8.225.193 'nginx -t' 2>&1
ssh root@10.8.225.193 'nginx -s reload' 2>&1


#ssh root@43.255.30.197 'rm -rf /usr/local/nginx/cache_data/*' 2>&1
#ssh root@43.255.30.197 'nginx -s reload' 2>&1

cdnray=`curl --request GET https://panel.cdnray.com:8443/accessToken --header 'SKC-RefreshToken: 51ebd34db8a0e5303628c8eb416a2941feafa8c08ed63a90e18db9cc072ce546' | jq ".accessToken" | sed 's/"//g'`
echo $cdnray
curl --request DELETE https://panel.cdnray.com:8443/api/v1/user/site/551/setting/currentCache -H "SKC-RefreshToken: 51ebd34db8a0e5303628c8eb416a2941feafa8c08ed63a90e18db9cc072ce546" -H "SKC-AccessToken: $cdnray"

aws cloudfront create-invalidation --distribution-id E3VDTIOH2789CT  --paths "/" "/*"
date
