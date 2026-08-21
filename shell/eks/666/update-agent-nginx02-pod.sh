#!/bin/sh
set -e
v=$1
p=$2
t=$3

#exp
#sh update-agent-ng02inx-pod.sh scmk 666-001

rm -rf /root/.kube/
aws eks update-kubeconfig --region ap-east-1 --name dgp-live

if kubectl get deployment.apps/"${v}-${p}-agent-ng02 &> /dev/null; then
  echo "Deployment "${v}-${p}-agent-ng02 存在，正在删除..."
  kubectl delete deployment.apps/"${v}-${p}-agent-ng02 --force --grace-period=0
  sleep 4
  echo "Deployment "${v}-${p}-agent-ng02 已删除。"
else
  echo "Deployment "${v}-${p}-agent-ng02 不存在，无需删除。"
fi

cat <<EOF > 111.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: "${v}-${p}-agent-ng02
  labels:
    app: "${v}-${p}-agent-ng02
spec:
  replicas: 1
  revisionHistoryLimit: 1
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 100%
      maxSurge: 0
  selector:
    matchLabels:
      app: "${v}-${p}-agent-ng02
  template:
    metadata:
      annotations:
        kubectl.kubernetes.io/restartedAt: "${date_now}"
      labels:
        app: "${v}-${p}-agent-ng02
    spec:
      nodeSelector:
        dgplive: "$v"-"$p"
      containers:
        - name: "${v}-${p}-agent-ng02
          image: public.ecr.aws/f2z7x9a1/ttko-666:sprin2boot-agent-ng-god
          imagePullPolicy: Always
          ports:
            - name: http
              containerPort: 80
          startupProbe:
            tcpSocket:
              port: 80
            initialDelaySeconds: 10
            periodSeconds: 5
            failureThreshold: 30

          readinessProbe:
            tcpSocket:
              port: 80
            periodSeconds: 5
            timeoutSeconds: 3
            failureThreshold: 2

          livenessProbe:
            tcpSocket:
              port: 80
            periodSeconds: 10
            timeoutSeconds: 3
            failureThreshold: 3
---
apiVersion: v1
kind: Service
metadata:
  name: "${v}-${p}-agent-ng02
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "external"
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internal"
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
    #service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*" # 或檢查對應 NLB 關閉 client IP preserve 的參數
    #service.beta.kubernetes.io/aws-load-balancer-target-group-attributes: "stickiness.enabled=true,deregistration_delay.timeout_seconds=15"
    # 【已改回 TCP 模式】避免 Spring Boot 根目錄回傳 403 造成 AWS 誤判 Unhealthy
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-protocol: "TCP"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-port: "80"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-interval-seconds: "10"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-healthy-threshold-count: "2"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-unhealthy-threshold-count: "2"
spec:
  type: LoadBalancer
  ports:
    - name: http
      port: 80
      targetPort: 80
      protocol: TCP
  selector:
    app: "${v}-${p}-agent-ng02
EOF

kubectl apply -f 111.yaml
rm -rf  111.*
kubectl rollout status deployment.apps/"$v"-agent-ng02
