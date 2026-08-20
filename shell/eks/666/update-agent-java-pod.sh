#!/bin/sh
set -e
v=$1
p=$2
e=$3
a=$4
b=$5
c=$6

# 定義時間變數，供 Deployment annotation 重啟標記使用
date_now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# exp
# sh update-agent-java-pod.sh scmk 001 scmk02-live.cluster-crq0wu4woeyc.ap-east-1.rds.amazonaws.com scmk-live-instance-1.crq0wu4woeyc.ap-east-1.rds.amazonaws.com:3306/scmk 10.7.200.10 logstash.taidagediao.com:4582

rm -rf /root/.kube/
aws eks update-kubeconfig --region ap-east-1 --name dgp-live

if kubectl get deployment.apps/"$v"-agent-java &> /dev/null; then
  echo "Deployment "$v"-agent-java 存在，正在刪除..."
  kubectl delete deployment.apps/"$v"-agent-java --force --grace-period=0
  sleep 4
  echo "Deployment "$v"-agent-java 已刪除。"
else
  echo "Deployment "$v"-agent-java 不存在，無需刪除。"
fi

cat << EOF > 123.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: "${v}-agent-java"
  labels:
    app: "${v}-agent-java"
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
      app: "${v}-agent-java"
  template:
    metadata:
      annotations:
        kubectl.kubernetes.io/restartedAt: "${date_now}"
        sidecar.opentelemetry.io/inject: "false"
        instrumentation.opentelemetry.io/inject-java: "false"
      labels:
        app: "${v}-agent-java"
    spec:
      serviceAccountName: s3-log-uploader-sa
      terminationGracePeriodSeconds: 60
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: topology.kubernetes.io/zone
          whenUnsatisfiable: ScheduleAnyway
          labelSelector:
            matchLabels:
              app: "${v}-agent-java"
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
              SEARCH_KEY=\$(echo "${v}-agent-java" | tr -d '-')
              echo "開始搜尋 S3 桶中關鍵字 [${v}-agent-java] 及 [\${SEARCH_KEY}] 的歷史 Log..."
              mkdir -p /data/logs

              S3_FILES=\$(aws s3 api list-objects-v2 --bucket kklo-logs --query "Contents[?contains(Key, '\${SEARCH_KEY}') || contains(Key, '${v}-agent-java')].Key" --output text --region ap-east-1 2>/dev/null || true)

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
        - name: "${v}-agent-java"
          image: public.ecr.aws/f2z7x9a1/ttko-666:springboot-agent-god
          imagePullPolicy: Always
          securityContext:
            privileged: true
          ports:
            - name: http
              containerPort: 8081
          env:
            - name: SPRING_DATASOURCE_MASTER_URL
              value: "jdbc:mysql://${e}:3306/${v}?serverTimezone=Asia/Shanghai&useSSL=false&useUnicode=true&characterEncoding=UTF-8"
            - name: SPRING_DATASOURCE_SLAVE_URL
              value: "jdbc:mysql://${a}?serverTimezone=Asia/Shanghai&useSSL=false&useUnicode=true&characterEncoding=UTF-8"
            - name: SPRING_DATASOURCE_USERNAME
              value: "scmk_user"
            - name: SPRING_DATASOURCE_PASSWORD
              value: "15ef2e33783d4d575ded2cf1df82e933ccd64c69"
            - name: SPRING_REDIS_IP
              value: "${b}"
            - name: SPRING_POD_NAME
              value: "${v}-agent-java"
            - name: SPRING_LOGSTASH_URL
              value: "${c}"
            - name: SPRING_TG_CHAT
              value: "-5269325874"
            - name: SPRING_TG_KEY
              value: "7710466331:AAGoFpFIt9Xd-C7QroulSReyd0SEs6OhbRc"

          volumeMounts:
            - name: log-volume
              mountPath: /data/logs

          startupProbe:
            tcpSocket:
              port: 8081
            initialDelaySeconds: 10
            periodSeconds: 5
            failureThreshold: 30

          readinessProbe:
            tcpSocket:
              port: 8081
            initialDelaySeconds: 20
            periodSeconds: 15
            timeoutSeconds: 3
            failureThreshold: 2

          livenessProbe:
            tcpSocket:
              port: 8081
            initialDelaySeconds: 20
            periodSeconds: 15
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
apiVersion: v1
kind: Service
metadata:
  name: "${v}-agent-java"
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "external"
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internal"
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-protocol: "TCP"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-port: "8081"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-interval-seconds: "10"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-healthy-threshold-count: "2"
    service.beta.kubernetes.io/aws-load-balancer-healthcheck-unhealthy-threshold-count: "2"
spec:
  type: LoadBalancer
  ports:
    - name: http
      port: 80
      targetPort: 8081
      protocol: TCP
  selector:
    app: "${v}-agent-java"
EOF

kubectl apply -f 123.yaml

rm -rf 123.yaml
kubectl rollout status deployment.apps/"$v"-agent-java
