#!/bin/sh
set -e
v=$1
p=$2
e=$3
a=$4
b=$5
c=$6

#exp
#sh /data/eks/room/update-appprojava-pod.sh scmk 001 scmk-room-master01.cbqaoyq2629x.ap-east-1.rds.amazonaws.com scmk-room-master01.cbqaoyq2629x.ap-east-1.rds.amazonaws.com:3306/scmk 10.2.221.118 logstash.taidagediao.com:4560

rm -rf /root/.kube/
aws eks update-kubeconfig --region ap-east-1 --name scmk-room

if kubectl get deployment.apps/"$v"-roompro-java &> /dev/null; then
  echo "Deployment "$v"-roompro-java 存在，正在删除..."
  kubectl delete deployment.apps/"$v"-roompro-java --force --grace-period=0
  sleep 4
  echo "Deployment "$v"-roompro-java 已删除。"
else
  echo "Deployment "$v"-roompro-java 不存在，无需删除。"
fi

echo "apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: "$v"-roompro-java
  name: "$v"-roompro-java
spec:
  strategy:
    type: RollingUpdate
  replicas: 1
  selector:
    matchLabels:
      app: "$v"-roompro-java
  template:
    metadata:
      labels:
        app: "$v"-roompro-java
    spec:
      containers:
        - image: 387125169234.dkr.ecr.ap-east-1.amazonaws.com/scmk-room:springboot-roompro-god
          name: "$v"-roompro-java
          imagePullPolicy: Always
          securityContext:
            privileged: true
          ports:
          - name: tcp
            containerPort: 80
          resources:
            requests:
              cpu: 0.4
              memory: 1024Mi    
          env:
            - name: SPRING_DATASOURCE_MASTER_URL
              value: "'jdbc:mysql://'"$e":3306/"$v"'?serverTimezone=CTT&useSSL=false&useUnicode=true&characterEncoding=UTF-8'"
            - name: SPRING_DATASOURCE_SLAVE_URL
              value: "'jdbc:mysql://'"$a"'?serverTimezone=CTT&useSSL=false&useUnicode=true&characterEncoding=UTF-8'"
            - name: SPRING_DATASOURCE_USERNAME
              value: "scmk_user"
            - name: SPRING_DATASOURCE_PASSWORD
              value: "0bbd40652416b05628587e9318542ecfec8b5747"
            - name: SPRING_REDIS_IP
              value: "$b"
            - name: SPRING_POD_NAME
              value: "$v"-roompro-java
            - name: SPRING_LOGSTASH_URL
              value: "$c"
            - name: SPRING_TG_CHAT
              value: "'"-4842005957"'"
            - name: SPRING_TG_KEY
              value: "7710466331:AAFCRoy92tpVjxEDar6IiRAw_YjBkj2TWPY"
          livenessProbe:
            tcpSocket:
              port: 80
            initialDelaySeconds: 20
            periodSeconds: 15
          readinessProbe:
            tcpSocket:
              port: 80
            initialDelaySeconds: 20
            periodSeconds: 15
      nodeSelector:
        scmkroom: "$v"-"$p"
---
apiVersion: v1
kind: Service
metadata:
  name: "$v"-roompro-java
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-type : "external"
    service.beta.kubernetes.io/aws-load-balancer-name: "nlb-"$v"-roompro-java"
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: "$v"-roompro-java
  sessionAffinity: None
  type: LoadBalancer
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: "$v"-roompro-java
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: "$v"-roompro-java
  minReplicas: 1
  maxReplicas: 6
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 60
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 75" > 123.yaml

kubectl apply -f 123.yaml

rm -rf  123.*
kubectl rollout status deployment.apps/"$v"-roompro-java
