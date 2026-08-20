#!/bin/sh
set -e
v=$1
p=$2
b=$3
c=$4

#刪除REDIS
EC2_ID=`aws ec2 describe-instances --filters "Name=private-ip-address,Values=$b" --query "Reservations[0].Instances[0].InstanceId" --output text`
aws ec2 terminate-instances --instance-ids "$EC2_ID" > /dev/null 2>&1
#刪除cdn-ray
#exp
#sh del-cdnray-domainid.sh y222
cdnray=`curl --request GET https://panel.cdnray.com:8443/accessToken --header 'SKC-RefreshToken: 51ebd34db8a0e5303628c8eb416a2941feafa8c08ed63a90e18db9cc072ce546' | jq ".accessToken" | sed 's/"//g'`
domainid=`curl --request GET --header 'Content-Type: application/json'  --header "SKC-RefreshToken: 51ebd34db8a0e5303628c8eb416a2941feafa8c08ed63a90e18db9cc072ce546" --header "SKC-AccessToken: $cdnray"  "https://panel.cdnray.com:8443/api/v1/user/site/551/domains?page=1&pageSize=200&keywords="$v"-666-websocke.taidagediao.com" | jq '.data[].id'`
curl --request DELETE   --header 'Content-Type: application/json'  --header "SKC-RefreshToken: 51ebd34db8a0e5303628c8eb416a2941feafa8c08ed63a90e18db9cc072ce546"   --header "SKC-AccessToken: $cdnray" \
    --data '{ "ids":['$domainid'] }' \
    https://panel.cdnray.com:8443/api/v1/user/site/551/domains
