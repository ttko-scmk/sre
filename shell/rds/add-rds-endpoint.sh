#!/bin/sh
set -e

v=$1  # cluster ID
p=$2  # endpoint name
i=$3
u=$4
q=$5

# exp:
# sh add-rds-endpoint.sh scmk-live scmk001-endpoint scmk001-slave01 scmk001-slave02 scmk001-slave03

# 動態組合 static-members
static_members=""

[ -n "$i" ] && static_members="$static_members $i"
[ -n "$u" ] && static_members="$static_members $u"
[ -n "$q" ] && static_members="$static_members $q"

# 檢查是否有任何 static member
if [ -z "$static_members" ]; then
  echo "❌ 請至少提供一個 static member"
  exit 1
fi

# 執行 AWS CLI
# 使用 eval 避免 split 問題（或改用 set -- $static_members）
eval aws rds create-db-cluster-endpoint \
  --db-cluster-identifier "$v" \
  --db-cluster-endpoint-identifier "$p" \
  --endpoint-type reader \
  --static-members $static_members \
  --tags Key=Name,Value=CustomReader --query "Endpoint" --output text
