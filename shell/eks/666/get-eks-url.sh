#!/bin/sh
set -e
v=$1

rm -rf /root/.kube/
aws eks update-kubeconfig --region ap-east-1 --name dgp-live > /dev/null 2>&1
#exp
#sh get-eks-url.sh scmk-agent-ng

kubectl get service/"$v" -o json | jq '.status.loadBalancer.ingress[].hostname' |sed -e 's/"//g'
