#!/bin/sh

set -e
v=$1
p=$2
b=$3

rm -rf /root/.kube/
aws eks update-kubeconfig --region ap-east-1 --name scmk-room

#exp
#sh /data/eks/room/del-eks-all.sh scmk 001 10.2.200.10

#刪除POD 服務
kubectl delete deployment.apps/"$v"-roompro-java
kubectl delete deployment.apps/"$v"-sysroom-ng
kubectl delete deployment.apps/"$v"-sysroomht-ng
kubectl delete deployment.apps/"$v"-websocke-java

#刪除HPA 
kubectl delete horizontalpodautoscaler.autoscaling/"$v"-roompro-java


#刪除AWS ELB
kubectl delete service/"$v"-roompro-java
kubectl delete service/"$v"-sysroom-ng
kubectl delete service/"$v"-sysroomht-ng
kubectl delete service/"$v"-websocke-java
kubectl delete ing/"$v"-websocke-java

#刪除NODE
aws cloudformation delete-stack --stack-name eksctl-scmk-room-nodegroup-"$v"-"$p"  --region ap-east-1

#刪除NGINX 
ssh 10.8.219.67 "rm -rf /usr/local/nginx/conf/vhosts/"$v"*"
ssh 10.8.219.67 "nginx -t"
ssh 10.8.219.67 "nginx -s reload"

ssh 10.8.225.193"rm -rf /usr/local/nginx/conf/vhosts/"$v"*"
ssh 10.8.225.193 "nginx -t"
ssh 10.8.225.193 "nginx -s reload"



#刪除REDIS
EC2_ID=`aws ec2 describe-instances --filters "Name=private-ip-address,Values=$b" --query "Reservations[0].Instances[0].InstanceId" --output text`
aws ec2 terminate-instances --instance-ids "$EC2_ID" > /dev/null 2>&1

#刪除cdn-ray

#exp
#sh del-cdnray-domainid.sh y222

cdnray=`curl --request GET https://panel.cdnray.com:8443/accessToken --header 'SKC-RefreshToken: 51ebd34db8a0e5303628c8eb416a2941feafa8c08ed63a90e18db9cc072ce546' | jq ".accessToken" | sed 's/"//g'`
domainid=`curl --request GET --header 'Content-Type: application/json'  --header "SKC-RefreshToken: 51ebd34db8a0e5303628c8eb416a2941feafa8c08ed63a90e18db9cc072ce546" --header "SKC-AccessToken: $cdnray"  "https://panel.cdnray.com:8443/api/v1/user/site/551/domains?page=1&pageSize=200&keywords="$v"-room-websocke.taidagediao.com" | jq '.data[].id'`

curl --request DELETE   --header 'Content-Type: application/json'  --header "SKC-RefreshToken: 51ebd34db8a0e5303628c8eb416a2941feafa8c08ed63a90e18db9cc072ce546"   --header "SKC-AccessToken: $cdnray" \
    --data '{ "ids":['$domainid'] }' \
    https://panel.cdnray.com:8443/api/v1/user/site/551/domains
