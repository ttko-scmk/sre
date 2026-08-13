#!/bin/sh
set -e
v=$1
p=$2

rm -rf /root/.kube/
aws eks update-kubeconfig --region ap-east-1 --name scmk-666

#exp
#sh del-eks-formation.sh scmk 001

aws cloudformation delete-stack --stack-name eksctl-scmk-666-nodegroup-"$v"-"$p"  --region ap-east-1
