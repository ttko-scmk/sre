#!/bin/sh
set -e
v=$1
rm -rf /root/.kube/
aws eks update-kubeconfig --region ap-east-1  --name scmk-room > /dev/null

#exp
#sh /data/eks/room/get-pod-status.sh scmk

kubectl get pod | grep -E "^NAME|$v"
