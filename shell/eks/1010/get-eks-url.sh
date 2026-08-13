#!/bin/sh
set -e
v=$1

#exp
#sh get-eks-url.sh scmk-agent-ng

kubectl get service/"$v" -o json | jq '.status.loadBalancer.ingress[].hostname' |sed -e 's/"//g'
