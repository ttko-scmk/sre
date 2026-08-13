#!/bin/bash
set -e

# S3上傳專用配置
readonly S3_AK="AKIAVUITVJRJG4N3ZY7L"
readonly S3_SK="DSDZ+Piyi20v23/goaHGC1OlujQYbPM9HgtQaxY7"
readonly S3_REGION="ap-east-1"
readonly S3_BUCKET="scmk-logss"
readonly EKS_CLUSTER="scmk-room"
readonly EKS_REGION="ap-east-1"

v=$1

echo "=== 階段1: 使用預設配置獲取Pod日誌 ==="

# 使用預設配置操作EKS
echo "配置EKS訪問..."
rm -rf /root/.kube/
aws eks update-kubeconfig --region "$EKS_REGION" --name "$EKS_CLUSTER" > /dev/null

echo "查找Pod: $v"
POD_NAME=$(kubectl get pods | grep "$v" | grep Running | awk '{print $1}')
if [ -z "$POD_NAME" ]; then
    echo "錯誤: 找不到運行的Pod"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="./pod_logs_${v}_${TIMESTAMP}"

echo "從Pod $POD_NAME 複製日誌..."
kubectl cp "$POD_NAME:/var/log" "$LOG_DIR/"

echo "✅ Pod日誌獲取完成"

echo "=== 階段2: 使用S3專用配置上傳 ==="

# 在子shell中使用S3專用配置上傳（不影響外部環境）
(
    export AWS_ACCESS_KEY_ID="$S3_AK"
    export AWS_SECRET_ACCESS_KEY="$S3_SK"
    export AWS_DEFAULT_REGION="$S3_REGION"
    unset AWS_SESSION_TOKEN
    
    echo "上傳日誌到S3..."
    echo "上傳.gz文件（設置為下載格式）..."
    aws s3 sync "$LOG_DIR/" "s3://$S3_BUCKET/$EKS_CLUSTER/${v}_${TIMESTAMP}/" \
        --exclude "*" \
        --include "*.gz" \
        --content-type "application/gzip" \
        --content-disposition "attachment"
    
    echo "上傳.log文件（設置為文本格式）..."
    aws s3 sync "$LOG_DIR/" "s3://$S3_BUCKET/$EKS_CLUSTER/${v}_${TIMESTAMP}/" \
        --exclude "*.gz" \
        --content-type "text/plain; charset=utf-8" 
)

echo "清理臨時文件..."
rm -rf "$LOG_DIR"

echo "✅ 完成! 日誌已上傳到: s3://$S3_BUCKET/pod_logs/${v}_${TIMESTAMP}/"
