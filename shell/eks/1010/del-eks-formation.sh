#!/bin/sh
set -e
v=$1
p=$2


#exp
#sh del-eks-formation.sh scmk 001

aws cloudformation delete-stack --stack-name eksctl-scmk-1010-nodegroup-"$v"-"$p"  --region ap-east-1
