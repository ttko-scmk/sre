#!/bin/sh
set -e
v=$1
p=$2

rm -rf /root/.kube/
aws eks update-kubeconfig --region ap-east-1 --name dgp-live

#exp
#sh del-eks-settlement.sh cs 101
#刪除POD 服務
kubectl delete deployment.apps/"$v"-settlement-java
#刪除NODE 服務
aws cloudformation delete-stack --stack-name eksctl-dgp-live-nodegroup-"$v"-"$p"  --region ap-east-1
