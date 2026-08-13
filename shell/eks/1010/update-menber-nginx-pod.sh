#!/bin/sh
set -e
v=$1
p=$2


#exp
#sh update-menber-nginx-pod.sh scmk 001

rm -rf /root/.kube/
aws eks update-kubeconfig --region ap-east-1 --name scmk-1010

if kubectl get deployment.apps/"$v"-mnber-ng &> /dev/null; then
  echo "Deployment "$v"-mnber-ng 存在，正在删除..."
  kubectl delete deployment.apps/"$v"-mnber-ng --force --grace-period=0
  sleep 4
  echo "Deployment "$v"-mnber-ng 已删除。"
else
  echo "Deployment "$v"-mnber-ng 不存在，无需删除。"
fi

echo "apiVersion: apps/v1
kind: Deployment
metadata:
  name: "$v"-mnber-ng
spec:
  selector:
    matchLabels:
      app: "$v"-mnber-ng
  replicas: 1
  template:
    metadata:
      labels:
        app: "$v"-mnber-ng
    spec:
      containers:
      - image: 387125169234.dkr.ecr.ap-east-1.amazonaws.com/scmk-1010-nginx:scmk-mnber-ng-god
        imagePullPolicy: Always
        name: "$v"-mnber-ng
        ports:
        - containerPort: 80
      nodeSelector:
        scmklive: "$v"-"$p"
---
apiVersion: v1
kind: Service
metadata:
  name: "$v"-mnber-ng
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-type : "external"
    service.beta.kubernetes.io/aws-load-balancer-name: "nlb-"$v"-mnber-ng"
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: "$v"-mnber-ng
  sessionAffinity: None
  type: LoadBalancer" > 111.yaml

kubectl apply -f 111.yaml
rm -rf  111.*
kubectl rollout status deployment.apps/"$v"-mnber-ng
