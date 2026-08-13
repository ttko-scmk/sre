#!/bin/sh
set -e
v=$1
p=$2
e=$3
a=$4
b=$5
c=$6

#exp
#sh update-websocke-java-pod.sh scmk 001 scmk-live-instance-1.crq0wu4woeyc.ap-east-1.rds.amazonaws.com:3306/scmk 10.7.200.10 logstash.taidagediao.com:4582

rm -rf /root/.kube/
aws eks update-kubeconfig --region ap-east-1 --name scmk-1010

if kubectl get deployment.apps/"$v"-websocke-java &> /dev/null; then
  echo "Deployment "$v"-websocke-java 存在，正在删除..."
  kubectl delete deployment.apps/"$v"-websocke-java --force --grace-period=0
  sleep 4
  echo "Deployment "$v"-websocke-java 已删除。"
else
  echo "Deployment "$v"-websocke-java 不存在，无需删除。"
fi


echo "apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: "$v"-websocke-java
  name: "$v"-websocke-java
spec:
  strategy:
    type: RollingUpdate
  replicas: 1
  selector:
    matchLabels:
      app: "$v"-websocke-java
  template:
    metadata:
      labels:
        app: "$v"-websocke-java
    spec:
      containers:
        - image: 387125169234.dkr.ecr.ap-east-1.amazonaws.com/scmk-1010-nginx:springboot-websocke-new
          name: "$v"-websocke-java
          imagePullPolicy: Always
          securityContext:
            privileged: true
          ports:
          - name: tcp
            containerPort: 8087
          env:
            - name: SPRING_DATASOURCE_MASTER_URL
              value: "'jdbc:mysql://'"$e":3306/"$v"'?serverTimezone=CTT&useSSL=false&useUnicode=true&characterEncoding=UTF-8'"
            - name: SPRING_DATASOURCE_SLAVE_URL
              value: "'jdbc:mysql://'"$a"'?serverTimezone=CTT&useSSL=false&useUnicode=true&characterEncoding=UTF-8'"
            - name: SPRING_DATASOURCE_USERNAME
              value: "scmk_user"
            - name: SPRING_DATASOURCE_PASSWORD
              value: "9faaec527d4d45c29f121230e17945f18d1a9567"
            - name: SPRING_REDIS_IP
              value: "$b"
            - name: SPRING_POD_NAME
              value: "$v"-websocke-java
            - name: SPRING_LOGSTASH_URL
              value: "$c"
            - name: SPRING_TG_CHAT
              value: "'"-4802376608"'"
            - name: SPRING_TG_KEY
              value: "7710466331:AAFCRoy92tpVjxEDar6IiRAw_YjBkj2TWPY"
          livenessProbe:
            tcpSocket:
              port: 8087
            initialDelaySeconds: 20
            periodSeconds: 15
          readinessProbe:
            tcpSocket:
              port: 8087
            initialDelaySeconds: 20
            periodSeconds: 15
      nodeSelector:
        scmklive: "$v"-"$p"
---
apiVersion: v1
kind: Service
metadata:
  name: "$v"-websocke-java
spec:
  ports:
    - name: http
      port: 8087
      targetPort: 8087
      protocol: TCP
  type: NodePort  
  selector:
    app: "$v"-websocke-java
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: "$v"-websocke-java
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip  
    alb.ingress.kubernetes.io/load-balancer-name: alb-"$v"-websocke-java
    alb.ingress.kubernetes.io/backend-protocol: HTTP
    alb.ingress.kubernetes.io/listen-ports: '[{\"HTTP\": 80}]'
    alb.ingress.kubernetes.io/connection-idle-timeout: \"600\"  
    alb.ingress.kubernetes.io/healthcheck-path: \"/healthz\" 
    alb.ingress.kubernetes.io/healthcheck-interval-seconds: \"30\"  
spec:
  ingressClassName: alb
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: "$v"-websocke-java
                port:
                  number: 8087" > 123.yaml

# 檢查 YAML 格式是否正確
kubectl apply --dry-run=client -f 123.yaml || { echo "YAML 格式錯誤"; exit 1; }

# 正式部署
kubectl apply -f 123.yaml

rm -rf  123.*
kubectl rollout status deployment.apps/"$v"-websocke-java
