#!/bin/sh
set -e
v=$1
p=$2
e=$3
a=$4
b=$5
c=$6

#exp
#sh update-downodds-java-pod.sh scmk 001 scmk-live-instance-1.crq0wu4woeyc.ap-east-1.rds.amazonaws.com:3306/scmk 10.7.200.10 logstash.taidagediao.com:4582

rm -rf /root/.kube/
aws eks update-kubeconfig --region ap-east-1 --name scmk-666

if kubectl get deployment.apps/"$v"-downodds-java &> /dev/null; then
  echo "Deployment "$v"-downodds-java 存在，正在删除..."
  kubectl delete deployment.apps/"$v"-downodds-java --force --grace-period=0
  sleep 4
  echo "Deployment "$v"-downodds-java 已删除。"
else
  echo "Deployment "$v"-downodds-java 不存在，无需删除。"
fi

echo "apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: "$v"-downodds-java
  name: "$v"-downodds-java
spec:
  strategy:
    type: RollingUpdate
  replicas: 1
  selector:
    matchLabels:
      app: "$v"-downodds-java
  template:
    metadata:
      labels:
        app: "$v"-downodds-java
    spec:
      containers:
        - image: 387125169234.dkr.ecr.ap-east-1.amazonaws.com/scmk-666:springboot-downodds-god
          name: "$v"-downodds-java
          imagePullPolicy: Always
          securityContext:
            privileged: true
          ports:
          - name: tcp
            containerPort: 8083
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
              value: "$v"-downodds-java
            - name: SPRING_LOGSTASH_URL
              value: "$c"
            - name: SPRING_TG_CHAT
              value: "'"-5269325874"'"
            - name: SPRING_TG_KEY
              value: "7710466331:AAFCRoy92tpVjxEDar6IiRAw_YjBkj2TWPY"
          livenessProbe:
            tcpSocket:
              port: 8083
            initialDelaySeconds: 20
            periodSeconds: 15
          readinessProbe:
            tcpSocket:
              port: 8083
            initialDelaySeconds: 20
            periodSeconds: 15
      nodeSelector:
        scmk666: "$v"-"$p"" > 123.yaml

kubectl apply -f 123.yaml

rm -rf  123.*
kubectl rollout status deployment.apps/"$v"-downodds-java
