#!/bin/sh
set -e
v=$1

#exp
#sh /data/eks/room/get-eks-websocke-url.sh scmk-websocke-java

kubectl get ing/"$v" -o json | jq '.status.loadBalancer.ingress[].hostname' |sed -e 's/"//g'
