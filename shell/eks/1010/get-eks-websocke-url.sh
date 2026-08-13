#!/bin/sh
set -e
v=$1

#exp
#sh get-eks-websocke-url.sh scmk-websocke-java

kubectl get ing/"$v" -o json | jq '.status.loadBalancer.ingress[].hostname' |sed -e 's/"//g'
