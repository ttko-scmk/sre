#!/bin/sh
set -e
v=$1
p=$2
e=$3
a=$4
b=$5
c=$6

#exp
#sh update-agent-java-pod.sh scmk 001 scmk02-live.cluster-crq0wu4woeyc.ap-east-1.rds.amazonaws.com scmk-live-instance-1.crq0wu4woeyc.ap-east-1.rds.amazonaws.com:3306/scmk 10.7.200.10 logstash.taidagediao.com:4582

rm -rf /root/.kube/
aws eks update-kubeconfig --region ap-east-1 --name dgp-live

if kubectl get deployment.apps/"$v"-agent-java &> /dev/null; then
  echo "Deployment "$v"-agent-java 存在，正在删除..."
  kubectl delete deployment.apps/"$v"-agent-java --force --grace-period=0
  sleep 4
  echo "Deployment "$v"-agent-java 已删除。"
else
  echo "Deployment "$v"-agent-java 不存在，无需删除。"
fi

echo "apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: "$v"-agent-java
  name: "$v"-agent-java
spec:
  strategy:
    type: RollingUpdate
  replicas: 1
  selector:
    matchLabels:
      app: "$v"-agent-java
  template:
    metadata:
      labels:
        app: "$v"-agent-java
    spec:
      containers:
        - image: 387125169234.dkr.ecr.ap-east-1.amazonaws.com/scmk-666:springboot-agent-god
          name: "$v"-agent-java
          imagePullPolicy: Always
          securityContext:
            privileged: true
          ports:
          - name: tcp
            containerPort: 8081
          env:
            - name: SPRING_DATASOURCE_MASTER_URL
              value: "'jdbc:mysql://'"$e":3306/"$v"'?serverTimezone=CTT&useSSL=false&useUnicode=true&characterEncoding=UTF-8'"
            - name: SPRING_DATASOURCE_SLAVE_URL
              value: "'jdbc:mysql://'"$a"'?serverTimezone=CTT&useSSL=false&useUnicode=true&characterEncoding=UTF-8'"
            - name: SPRING_DATASOURCE_USERNAME
              value: "scmk_user"
            - name: SPRING_DATASOURCE_PASSWORD
              value: "15ef2e33783d4d575ded2cf1df82e933ccd64c69"
            - name: SPRING_REDIS_IP
              value: "$b"
            - name: SPRING_POD_NAME
              value: "$v"-agent-java
            - name: SPRING_LOGSTASH_URL
              value: "$c"
            - name: SPRING_TG_CHAT
              value: "'"-5269325874"'"
            - name: SPRING_TG_KEY
              value: "7710466331:AAFCRoy92tpVjxEDar6IiRAw_YjBkj2TWPY"
          livenessProbe:
            tcpSocket:
              port: 8081
            initialDelaySeconds: 20
            periodSeconds: 15
          readinessProbe:
            tcpSocket:
              port: 8081
            initialDelaySeconds: 20
            periodSeconds: 15
      nodeSelector:
        scmk666: "$v"-"$p"
---
apiVersion: v1
kind: Service
metadata:
  name: "$v"-agent-java
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-type : "external"
    service.beta.kubernetes.io/aws-load-balancer-name: "nlb-"$v"-agent-java"
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 8081
  selector:
    app: "$v"-agent-java
  sessionAffinity: None
  type: LoadBalancer" > 123.yaml

kubectl apply -f 123.yaml

rm -rf  123.*
kubectl rollout status deployment.apps/"$v"-agent-java
