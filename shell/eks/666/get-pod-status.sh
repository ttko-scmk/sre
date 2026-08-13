#!/bin/sh
set -e
v=$1
rm -rf /root/.kube/
aws eks update-kubeconfig --region ap-east-1  --name scmk-666 > /dev/null
#exp
#sh /data/eks/666/get-pod-status.sh aolinpike

kubectl get pod | grep -E "^NAME|$v"
