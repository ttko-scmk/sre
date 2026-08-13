#!/bin/bash
set -e
v=$1
p=$2
#exp
#sh list-rds-cluster-w.sh scmk02-live

aws rds describe-db-clusters --db-cluster-identifier "$v" | jq '.DBClusters[].Endpoint' | sed  's/"//g'
