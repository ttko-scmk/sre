#!/bin/sh
set -e
v=$1
p=$2
t=$3

#exp
#sh add-eks-node.sh scmk 001 c6g.xlarge
rm -rf /root/.kube/
aws eks update-kubeconfig --region ap-east-1 --name scmk-room
#產EKS
echo "
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: scmk-room
  region: ap-east-1
  version: '"1.33"'

managedNodeGroups:
  - name: "$v"-"$p"
    labels: { scmkroom: "$v"-"$p" }
    instanceType: "$t"
    privateNetworking: true
    desiredCapacity: 1
    minSize: 1
    maxSize: 6
    volumeSize: 100
    volumeType: gp2
    iam:
      withAddonPolicies:
        autoScaler: true
        cloudWatch: true
    tags:
      k8s.io/cluster-autoscaler/enabled: '"true"'
      k8s.io/cluster-autoscaler/scmk-room: '"owned"'" > cluster-node.yaml

eksctl create nodegroup --config-file=cluster-node.yaml --skip-outdated-addons-check=true
