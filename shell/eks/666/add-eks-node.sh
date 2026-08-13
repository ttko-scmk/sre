#!/bin/sh
set -e
v=$1
p=$2
t=$3

#exp
#sh add-eks-node.sh scmk 001 t4g.large
rm -rf /root/.kube/
aws eks update-kubeconfig --region ap-east-1 --name scmk-666
#產EKS
echo "
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: scmk-666
  region: ap-east-1
  version: '"1.35"'

managedNodeGroups:
  - name: "$v"-"$p"
    labels: { scmk666: "$v"-"$p" }
    instanceType: "$t"
    privateNetworking: true
    desiredCapacity: 1
    minSize: 1
    maxSize: 4
    volumeSize: 100
    volumeType: gp3
    iam:
      withAddonPolicies:
        autoScaler: true
        cloudWatch: true
    tags:
      k8s.io/cluster-autoscaler/enabled: '"true"'
      k8s.io/cluster-autoscaler/scmk-live: '"owned"'" > cluster-node.yaml

eksctl create nodegroup --config-file=cluster-node.yaml --skip-outdated-addons-check=true

