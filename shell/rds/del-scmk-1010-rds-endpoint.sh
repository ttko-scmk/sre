#!/bin/sh
set -e

v=$1  # endpoint name
p=$2  # 修改为您的默认区域
i=$3
#exp
#sh del-scmk-1010-rds-endpoint.sh test001-endpoint ap-east-1

aws rds delete-db-cluster-endpoint --db-cluster-endpoint-identifier "$v" --region "$p" > /dev/null 2>&1
