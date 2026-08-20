#!/bin/sh
set -e
v=$1
p=$2
b=$3
c=$4
rm -rf /root/.kube/
aws eks update-kubeconfig --region ap-east-1 --name dgp-live
#exp
#sh del-eks-all.sh scmk 001 10.7.200.10
#刪除POD 服務
kubectl delete deployment.apps/"${v}-${p}"-agent-java
kubectl delete deployment.apps/"${v}-${p}"-agent-ng
kubectl delete deployment.apps/"${v}-${p}"-agent-ng02 --ignore-not-found=true
kubectl delete deployment.apps/"${v}-${p}"-downodds-java
kubectl delete deployment.apps/"${v}-${p}"-mnber-ng
kubectl delete deployment.apps/"${v}-${p}"-mnber-ng02 --ignore-not-found=true
kubectl delete deployment.apps/"${v}-${p}"-portal-java
kubectl delete deployment.apps/"${v}-${p}"-schedule-java
kubectl delete deployment.apps/"${v}-${p}"-settlement-java
kubectl delete deployment.apps/"${v}-${p}"-websocke-java
#刪除AWS ELB
kubectl delete service/"${v}-${p}"-agent-java
kubectl delete service/"${v}-${p}"-agent-ng
kubectl delete service/"${v}-${p}"-mnber-ng
kubectl delete service/"${v}-${p}"-agent-ng02 --ignore-not-found=true
kubectl delete service/"${v}-${p}"-mnber-ng02 --ignore-not-found=true
kubectl delete service/"${v}-${p}"-portal-java
kubectl delete service/"${v}-${p}"-websocke-java
kubectl delete ing/"${v}-${p}"-websocke-java
sleep 5
#刪除NODE
aws cloudformation delete-stack --stack-name eksctl-dgp-live-nodegroup-"$v"-"$p"  --region ap-east-1
sleep 5
aws cloudformation delete-stack --stack-name eksctl-dgp-live-nodegroup-"$v"-"$c"  --region ap-east-1
#刪除NGINX 
ssh 10.8.217.207 "rm -rf /usr/local/nginx/conf/vhosts/"${v}-${p}"*"
ssh 10.8.217.207 "nginx -t"
ssh 10.8.217.207 "nginx -s reload"
sleep 2
ssh 10.8.229.5 "rm -rf /usr/local/nginx/conf/vhosts/"${v}-${p}"*"
ssh 10.8.229.5 "nginx -t"
ssh 10.8.229.5 "nginx -s reload"
sleep 2
ssh 10.8.243.6 "rm -rf /usr/local/nginx/conf/vhosts/"${v}-${p}"*"
ssh 10.8.243.6 "nginx -t"
ssh 10.8.243.6 "nginx -s reload"
sh /data/eks/666/del-eks-all02.sh $v $p $b $c
