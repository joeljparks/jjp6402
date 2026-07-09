#!/usr/bin/env bash
set -euo pipefail

NAME_PREFIX="${NAME_PREFIX:-jjp6402}"
AWS_REGION="${AWS_REGION:-us-east-2}"
EKS_CLUSTER_NAME="${EKS_CLUSTER_NAME:-${NAME_PREFIX}-eks}"
APP_NAMESPACE="${APP_NAMESPACE:-tasky}"
APP_INGRESS="${APP_INGRESS:-tasky}"
LBC_NAMESPACE="${LBC_NAMESPACE:-kube-system}"
GATEKEEPER_NAMESPACE="${GATEKEEPER_NAMESPACE:-gatekeeper-system}"
ALB_NAME="${ALB_NAME:-${NAME_PREFIX}-alb}"

if ! aws eks describe-cluster --name "$EKS_CLUSTER_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
  echo "EKS cluster ${EKS_CLUSTER_NAME} does not exist; Kubernetes cleanup skipped."
  exit 0
fi

CLUSTER_VPC_ID=$(aws eks describe-cluster \
  --name "$EKS_CLUSTER_NAME" \
  --region "$AWS_REGION" \
  --query 'cluster.resourcesVpcConfig.vpcId' \
  --output text)

aws eks update-kubeconfig --name "$EKS_CLUSTER_NAME" --region "$AWS_REGION"

kubectl delete ingress "$APP_INGRESS" -n "$APP_NAMESPACE" --ignore-not-found=true || true

for attempt in $(seq 1 60); do
  ALB_COUNT=$(aws elbv2 describe-load-balancers \
    --region "$AWS_REGION" \
    --query "length(LoadBalancers[?VpcId=='${CLUSTER_VPC_ID}' && LoadBalancerName=='${ALB_NAME}'])" \
    --output text 2>/dev/null || echo 0)

  if [ "$ALB_COUNT" = "0" ]; then
    echo "Application ALB ${ALB_NAME} is absent."
    break
  fi

  echo "Waiting for application ALB ${ALB_NAME} to be deleted (${attempt}/60)."
  sleep 10

done

kubectl delete namespace "$APP_NAMESPACE" --ignore-not-found=true || true
helm uninstall aws-load-balancer-controller -n "$LBC_NAMESPACE" || true
helm uninstall gatekeeper -n "$GATEKEEPER_NAMESPACE" || true
kubectl delete namespace "$GATEKEEPER_NAMESPACE" --ignore-not-found=true || true

echo "Application Kubernetes cleanup complete."
