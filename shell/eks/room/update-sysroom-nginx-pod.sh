#!/bin/sh
set -e
v=$1
p=$2
t=$3

#exp
#sh /data/eks/room/update-sysroom-nginx-pod.sh scmk 001

rm -rf /root/.kube/
aws eks update-kubeconfig --region ap-east-1 --name scmk-room

if kubectl get deployment.apps/"$v"-sysroom-ng &> /dev/null; then
  echo "Deployment "$v"-sysroom-ng 存在，正在删除..."
  kubectl delete deployment.apps/"$v"-sysroom-ng --force --grace-period=0
  sleep 4
  echo "Deployment "$v"-sysroom-ng 已删除。"
else
  echo "Deployment "$v"-sysroom-ng 不存在，无需删除。"
fi

echo "apiVersion: apps/v1
kind: Deployment
metadata:
  name: "$v"-sysroom-ng
spec:
  selector:
    matchLabels:
      app: "$v"-sysroom-ng
  replicas: 1
  template:
    metadata:
      labels:
        app: "$v"-sysroom-ng
    spec:
      containers:
      - image: 387125169234.dkr.ecr.ap-east-1.amazonaws.com/scmk-room:scmk-sysroom-god
        imagePullPolicy: Always
        name: "$v"-sysroom-ng
        ports:
        - containerPort: 80
      nodeSelector:
        scmkroom: "$v"-"$p"
---
apiVersion: v1
kind: Service
metadata:
  name: "$v"-sysroom-ng
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-type : "external"
    service.beta.kubernetes.io/aws-load-balancer-name: "nlb-"$v"-sysroom-ng"
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: "$v"-sysroom-ng
  sessionAffinity: None
  type: LoadBalancer" > 111.yaml

kubectl apply -f 111.yaml
rm -rf  111.*
kubectl rollout status deployment.apps/"$v"-sysroom-ng
