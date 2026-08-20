#!/bin/sh
set -e
v=$1
p=$2

rm -rf /root/.kube/
aws eks update-kubeconfig --region ap-east-1 --name dgp-live

#exp
#sh del-eks-formation.sh scmk 001

aws cloudformation delete-stack --stack-name eksctl-dgp-live-nodegroup-"$v"-"$p"  --region ap-east-1
