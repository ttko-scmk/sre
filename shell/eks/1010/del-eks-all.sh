#!/bin/sh

set -e
v=$1
p=$2
b=$3

rm -rf /root/.kube/
aws eks update-kubeconfig --region ap-east-1 --name scmk-1010

#exp
#sh del-eks-all.sh scmk 001 10.7.200.10

#刪除POD 服務
kubectl delete deployment.apps/"$v"-agent-java
kubectl delete deployment.apps/"$v"-agent-ng
kubectl delete deployment.apps/"$v"-agent-ng02 --ignore-not-found=true
kubectl delete deployment.apps/"$v"-downodds-java
kubectl delete deployment.apps/"$v"-mnber-ng
kubectl delete deployment.apps/"$v"-mnber-ng02 --ignore-not-found=true
kubectl delete deployment.apps/"$v"-portal-java
kubectl delete deployment.apps/"$v"-schedule-java
kubectl delete deployment.apps/"$v"-settlement-java
kubectl delete deployment.apps/"$v"-websocke-java

#刪除AWS ELB
kubectl delete service/"$v"-agent-java
kubectl delete service/"$v"-agent-ng
kubectl delete service/"$v"-mnber-ng
kubectl delete service/"$v"-agent-ng02 --ignore-not-found=true
kubectl delete service/"$v"-mnber-ng02 --ignore-not-found=true
kubectl delete service/"$v"-portal-java
kubectl delete service/"$v"-websocke-java
kubectl delete ing/"$v"-websocke-java

#刪除NODE
aws cloudformation delete-stack --stack-name eksctl-scmk-1010-nodegroup-"$v"-"$p"  --region ap-east-1

#刪除NGINX 
ssh 10.8.221.196 "rm -rf /usr/local/nginx/conf/vhosts/"$v"*"
ssh 10.8.221.196 "nginx -t"
ssh 10.8.221.196 "nginx -s reload"

ssh 10.8.231.43 "rm -rf /usr/local/nginx/conf/vhosts/"$v"*"
ssh 10.8.231.43 "nginx -t"
ssh 10.8.231.43 "nginx -s reload"

ssh 10.8.244.234 "rm -rf /usr/local/nginx/conf/vhosts/"$v"*"
ssh 10.8.244.234 "nginx -t"
ssh 10.8.244.234 "nginx -s reload"



#刪除REDIS
EC2_ID=`aws ec2 describe-instances --filters "Name=private-ip-address,Values=$b" --query "Reservations[0].Instances[0].InstanceId" --output text`
aws ec2 terminate-instances --instance-ids "$EC2_ID" > /dev/null 2>&1

#刪除cdn-ray

#exp
#sh del-cdnray-domainid.sh y222

cdnray=`curl --request GET https://panel.cdnray.com:8443/accessToken --header 'SKC-RefreshToken: 51ebd34db8a0e5303628c8eb416a2941feafa8c08ed63a90e18db9cc072ce546' | jq ".accessToken" | sed 's/"//g'`
domainid=`curl --request GET --header 'Content-Type: application/json'  --header "SKC-RefreshToken: 51ebd34db8a0e5303628c8eb416a2941feafa8c08ed63a90e18db9cc072ce546" --header "SKC-AccessToken: $cdnray"  "https://panel.cdnray.com:8443/api/v1/user/site/551/domains?page=1&pageSize=200&keywords="$v"-websocke.taidagediao.com" | jq '.data[].id'`

curl --request DELETE   --header 'Content-Type: application/json'  --header "SKC-RefreshToken: 51ebd34db8a0e5303628c8eb416a2941feafa8c08ed63a90e18db9cc072ce546"   --header "SKC-AccessToken: $cdnray" \
    --data '{ "ids":['$domainid'] }' \
    https://panel.cdnray.com:8443/api/v1/user/site/551/domains
