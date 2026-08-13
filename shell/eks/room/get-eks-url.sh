#!/bin/sh
set -e
v=$1

#exp
#sh /data/eks/room/get-eks-url.sh scmk-roompro-java

kubectl get service/"$v" -o json | jq '.status.loadBalancer.ingress[].hostname' |sed -e 's/"//g'
