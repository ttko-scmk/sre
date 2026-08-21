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
aws eks update-kubeconfig --region ap-east-1 --name scmk-666

if kubectl get deployment.apps/"$v"-websocke-java &> /dev/null; then
  echo "Deployment "$v"-websocke-java 存在，正在删除..."
  kubectl delete deployment.apps/"$v"-websocke-java --force --grace-period=0
  sleep 4
  echo "Deployment "$v"-websocke-java 已删除。"
else
  echo "Deployment "$v"-websocke-java 不存在，无需删除。"
fi

cat <<EOF > 123.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: "${v}-${p}-websocke-java"
  labels:
    app: "${v}-${p}-websocke-java"
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
      app: "${v}-${p}-websocke-java"
  template:
    metadata:
      annotations:
        kubectl.kubernetes.io/restartedAt: "${date_now}"
        sidecar.opentelemetry.io/inject: "false"
        instrumentation.opentelemetry.io/inject-java: "false"
      labels:
        app: "${v}-${p}-websocke-java"
    spec:
      serviceAccountName: s3-log-uploader-sa
      terminationGracePeriodSeconds: 60
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: topology.kubernetes.io/zone
          whenUnsatisfiable: ScheduleAnyway
          labelSelector:
            matchLabels:
              app: "${v}-${p}-websocke-java"
      nodeSelector:
        dgplive: "${v}-${p}"
      volumes:
        - name: log-volume
          emptyDir: {}
      # [1] initContainers: 容器啟動前先至 S3 下載歷史 Log 備份
      initContainers:
        - name: init-fetch-s3-log
          image: amazon/aws-cli:latest
          command: ["/bin/sh", "-c"]
          args:
            - |
              SEARCH_KEY=\$(echo ""${v}-${p}-websocke-java"" | tr -d '-')
              echo "開始搜尋 S3 桶中關鍵字 ["${v}-${p}-websocke-java"] 及 [\${SEARCH_KEY}] 的歷史 Log..."
              mkdir -p /data/logs

              S3_FILES=\$(aws s3 api list-objects-v2 --bucket kklo-logs --query "Contents[?contains(Key, '\${SEARCH_KEY}') || contains(Key, '"${v}-${p}-websocke-java"')].Key" --output text --region ap-east-1 2>/dev/null || true)

              if [ -n "\${S3_FILES}" ] && [ "\${S3_FILES}" != "None" ]; then
                for S3_KEY in \${S3_FILES}; do
                  if echo "\${S3_KEY}" | grep -q "\.log\$"; then
                    LOCAL_FILE="/data/logs/\${S3_KEY}"
                    LOCAL_DIR=\$(dirname "\${LOCAL_FILE}")
                    mkdir -p "\${LOCAL_DIR}"
                    echo "下載 S3 歷史檔案: \${S3_KEY} -> \${LOCAL_FILE}"
                    aws s3 cp "s3://kklo-logs/\${S3_KEY}" "\${LOCAL_FILE}" --region ap-east-1 || true
                  fi
                done
              else
                echo "未在 S3 找到歷史日誌，跳過下載。"
              fi
          volumeMounts:
            - name: log-volume
              mountPath: /data/logs

      containers:
        # 主服務容器
        - name: "${v}-${p}-websocke-java"
          image: public.ecr.aws/f2z7x9a1/ttko-666:springboot-websocke-god
          imagePullPolicy: Always
          ports:
            - name: http
              containerPort: 8087
          env:
            - name: SPRING_DATASOURCE_MASTER_URL
              value: "jdbc:mysql://${e}:3306/${v}?serverTimezone=Asia/Shanghai&useSSL=false&useUnicode=true&characterEncoding=UTF-8"
            - name: SPRING_DATASOURCE_SLAVE_URL
              value: "jdbc:mysql://${a}?serverTimezone=Asia/Shanghai&useSSL=false&useUnicode=true&characterEncoding=UTF-8"
            - name: SPRING_DATASOURCE_USERNAME
              value: "admin"
            - name: SPRING_DATASOURCE_PASSWORD
              value: "ETxERwhkgT5DCATzUmQNNCUpvEddxFeM"
            - name: SPRING_REDIS_IP
              value: "${b}"
            - name: SPRING_NAME
              value: "${v}-${p}"
            - name: SPRING_POD_NAME
              value: ""${v}-${p}-websocke-java""
            - name: SPRING_LOGSTASH_URL
              value: "${c}"
            - name: SPRING_TG_CHAT
              value: "-4802376608"
            - name: SPRING_TG_KEY
              value: "7710466331:AAGoFpFIt9Xd-C7QroulSReyd0SEs6OhbRc"
          
          volumeMounts:
            - name: log-volume
              mountPath: /data/logs

          startupProbe:
            tcpSocket:
              port: 8087
            initialDelaySeconds: 10
            periodSeconds: 5
            failureThreshold: 30

          readinessProbe:
            tcpSocket:
              port: 8087
            periodSeconds: 5
            timeoutSeconds: 3
            failureThreshold: 2

          livenessProbe:
            tcpSocket:
              port: 8087
            periodSeconds: 10
            timeoutSeconds: 3
            failureThreshold: 3

        # [2] Sidecar: 運行中即時且持續同步當天 Log 至 S3
        - name: log-to-s3-sidecar
          image: amazon/aws-cli:latest
          command: ["/bin/sh", "-c"]
          args:
            - |
              echo "啟動 Sidecar 僅限當天 Log 的即時同步服務..."
              while true; do
                TODAY=\$(date +'%Y-%m-%d')

                find /data/logs -type f -name "*.log" | while read -r LOCAL_PATH; do
                  FILENAME=\$(basename "\${LOCAL_PATH}")
                  
                  if echo "\${FILENAME}" | grep -q "\${TODAY}" || ! echo "\${FILENAME}" | grep -qE "[0-9]{4}-[0-9]{2}-[0-9]{2}"; then
                    REL_PATH=\$(echo "\${LOCAL_PATH}" | sed 's|^/data/logs/||')
                    S3_TARGET="s3://kklo-logs/\${REL_PATH}"

                    aws s3 cp "\${LOCAL_PATH}" "\${S3_TARGET}" --region ap-east-1 --no-guess-mime-type --content-type "text/plain; charset=utf-8"
                  fi
                done
                sleep 30
              done
          volumeMounts:
            - name: log-volume
              mountPath: /data/logs
          lifecycle:
            preStop:
              exec:
                command:
                  - "/bin/sh"
                  - "-c"
                  - |
                    TODAY=\$(date +'%Y-%m-%d')
                    find /data/logs -type f -name "*.log" | while read -r LOCAL_PATH; do
                      FILENAME=\$(basename "\${LOCAL_PATH}")
                      if echo "\${FILENAME}" | grep -q "\${TODAY}" || ! echo "\${FILENAME}" | grep -qE "[0-9]{4}-[0-9]{2}-[0-9]{2}"; then
                        REL_PATH=\$(echo "\${LOCAL_PATH}" | sed 's|^/data/logs/||')
                        aws s3 cp "\${LOCAL_PATH}" "s3://kklo-logs/\${REL_PATH}" --region ap-east-1 --no-guess-mime-type --content-type "text/plain; charset=utf-8"
                      fi
                    done
---
# Service 定義
apiVersion: v1
kind: Service
metadata:
  name: "${v}-${p}-websocke-java"
spec:
  type: NodePort
  selector:
    app: "${v}-${p}-websocke-java"
  ports:
    - port: 8087
      targetPort: 8087
      protocol: TCP
      name: http
---
# WebSocket 優化版 Ingress (已修正 annotations 縮排問題)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: "${v}-${p}-websocke-java"-ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    
    # 模式為 instance (透過 NodePort 轉發)
    alb.ingress.kubernetes.io/target-type: instance
    alb.ingress.kubernetes.io/load-balancer-name: ""${v}-${p}-websocke-java"-alb"
    
    # 1. WebSocket 長連線逾時設定 (3600 秒)
    alb.ingress.kubernetes.io/load-balancer-attributes: idle_timeout.timeout_seconds=3600
    
    # 2. 健康檢查路徑與狀態碼
    alb.ingress.kubernetes.io/healthcheck-protocol: HTTP
    alb.ingress.kubernetes.io/healthcheck-path: /
    alb.ingress.kubernetes.io/healthcheck-port: traffic-port
    alb.ingress.kubernetes.io/success-codes: "200-320,404"
    
    alb.ingress.kubernetes.io/healthcheck-interval-seconds: "15"
    alb.ingress.kubernetes.io/healthcheck-timeout-seconds: "5"
    alb.ingress.kubernetes.io/healthy-threshold-count: "2"
    alb.ingress.kubernetes.io/unhealthy-threshold-count: "2"
spec:
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: "${v}-${p}-websocke-java"
                port:
                  number: 8087
EOF

# 檢查 YAML 格式是否正確
kubectl apply --dry-run=client -f 123.yaml || { echo "YAML 格式錯誤"; exit 1; }

# 正式部署
kubectl apply -f 123.yaml

rm -rf  123.*
kubectl rollout status deployment.apps/"$v"-websocke-java
