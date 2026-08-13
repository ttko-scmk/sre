#!/bin/sh
set -e
v=$1
p=$2
t=$3

#exp
#sh update-agent-nginx-pod.sh scmk 001

rm -rf /root/.kube/
aws eks update-kubeconfig --region ap-east-1 --name scmk-666

if kubectl get deployment.apps/"$v"-agent-ng &> /dev/null; then
  echo "Deployment "$v"-agent-ng 存在，正在删除..."
  kubectl delete deployment.apps/"$v"-agent-ng --force --grace-period=0
  sleep 4
  echo "Deployment "$v"-agent-ng 已删除。"
else
  echo "Deployment "$v"-agent-ng 不存在，无需删除。"
fi

echo "apiVersion: apps/v1
kind: Deployment
metadata:
  name: "$v"-agent-ng
spec:
  selector:
    matchLabels:
      app: "$v"-agent-ng
  replicas: 1
  template:
    metadata:
      labels:
        app: "$v"-agent-ng
    spec:
      containers:
      - image: 387125169234.dkr.ecr.ap-east-1.amazonaws.com/scmk-666:scmk-agent-ng-god
        imagePullPolicy: Always
        name: "$v"-agent-ng
        ports:
        - containerPort: 80
      nodeSelector:
        scmk666: "$v"-"$p"
---
apiVersion: v1
kind: Service
metadata:
  name: "$v"-agent-ng
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-type : "external"
    service.beta.kubernetes.io/aws-load-balancer-name: "nlb-"$v"-agent-ng"
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: "$v"-agent-ng
  sessionAffinity: None
  type: LoadBalancer" > 111.yaml

kubectl apply -f 111.yaml
rm -rf  111.*
kubectl rollout status deployment.apps/"$v"-agent-ng
