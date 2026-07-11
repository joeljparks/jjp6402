#!/usr/bin/env bash
set -euo pipefail

NAME_PREFIX="${NAME_PREFIX:-jjp6402}"
AWS_REGION="${AWS_REGION:-us-east-2}"
EKS_CLUSTER_NAME="${EKS_CLUSTER_NAME:-${NAME_PREFIX}-eks}"
GATEKEEPER_VERSION="${GATEKEEPER_VERSION:-3.22.2}"
AWS_LBC_CHART_VERSION="${AWS_LBC_CHART_VERSION:-1.14.0}"
MONGODB_APP_SECRET_NAME="${MONGODB_APP_SECRET_NAME:-${NAME_PREFIX}-mongodb-app}"
MONGODB_APP_NAMESPACE="${MONGODB_APP_NAMESPACE:-tasky}"

aws eks update-kubeconfig \
  --name "$EKS_CLUSTER_NAME" \
  --region "$AWS_REGION"

kubectl create namespace gatekeeper-system \
  --dry-run=client \
  -o yaml |
kubectl apply -f -

helm repo add gatekeeper \
  https://open-policy-agent.github.io/gatekeeper/charts \
  >/dev/null 2>&1 || true

helm repo add eks \
  https://aws.github.io/eks-charts \
  >/dev/null 2>&1 || true

helm repo update >/dev/null

helm upgrade --install gatekeeper gatekeeper/gatekeeper \
  --version "$GATEKEEPER_VERSION" \
  --namespace gatekeeper-system \
  --wait \
  --timeout 10m

GATEKEEPER_MANIFEST_DIR="${CODEBUILD_SRC_DIR:-$(pwd)}/app/tasky/k8s/gatekeeper"

kubectl apply \
  -f "${GATEKEEPER_MANIFEST_DIR}/require-non-root-template.yaml"

kubectl apply \
  -f "${GATEKEEPER_MANIFEST_DIR}/require-signature-annotation-template.yaml"

wait_for_constraint_template() {
  local template_name="$1"
  local crd_name="$2"
  local timeout_seconds="${3:-180}"
  local elapsed=0

  until [[ "$(kubectl get constrainttemplate "$template_name" \
    -o jsonpath='{.status.created}' 2>/dev/null || true)" == "true" ]]; do
    if (( elapsed >= timeout_seconds )); then
      echo "ConstraintTemplate ${template_name} did not reach status.created=true." >&2
      kubectl get constrainttemplate "$template_name" -o yaml >&2 || true
      kubectl logs -n gatekeeper-system \
        -l control-plane=controller-manager \
        --tail=100 >&2 || true
      exit 1
    fi

    sleep 3
    elapsed=$((elapsed + 3))
  done

  elapsed=0
  until kubectl get "crd/${crd_name}" >/dev/null 2>&1; do
    if (( elapsed >= timeout_seconds )); then
      echo "Constraint CRD ${crd_name} was not created." >&2
      kubectl get constrainttemplate "$template_name" -o yaml >&2 || true
      kubectl logs -n gatekeeper-system \
        -l control-plane=controller-manager \
        --tail=100 >&2 || true
      exit 1
    fi

    sleep 3
    elapsed=$((elapsed + 3))
  done

  kubectl wait \
    --for=condition=Established \
    "crd/${crd_name}" \
    --timeout="${timeout_seconds}s"
}

wait_for_constraint_template \
  "k8srequirenonroot" \
  "k8srequirenonroot.constraints.gatekeeper.sh"

wait_for_constraint_template \
  "k8srequiresignatureannotation" \
  "k8srequiresignatureannotation.constraints.gatekeeper.sh"

kubectl apply \
  -f "${GATEKEEPER_MANIFEST_DIR}/require-non-root-constraint.yaml"

kubectl apply \
  -f "${GATEKEEPER_MANIFEST_DIR}/require-signature-annotation-constraint.yaml"

LBC_ROLE_ARN="$(terraform output -raw aws_load_balancer_controller_role_arn)"
VPC_ID="$(terraform output -raw vpc_id)"

cat <<YAML | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aws-load-balancer-controller
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: ${LBC_ROLE_ARN}
YAML

helm upgrade --install \
  aws-load-balancer-controller \
  eks/aws-load-balancer-controller \
  --version "$AWS_LBC_CHART_VERSION" \
  --namespace kube-system \
  --set "clusterName=${EKS_CLUSTER_NAME}" \
  --set "region=${AWS_REGION}" \
  --set "vpcId=${VPC_ID}" \
  --set "serviceAccount.create=false" \
  --set "serviceAccount.name=aws-load-balancer-controller" \
  --wait \
  --timeout 10m

kubectl create namespace "$MONGODB_APP_NAMESPACE" \
  --dry-run=client \
  -o yaml |
kubectl apply -f -

MONGODB_URL="$(terraform output -raw mongodb_app_connection_string)"
SECRET_KEY="$(terraform output -raw jwt_secret)"

kubectl create secret generic "$MONGODB_APP_SECRET_NAME" \
  --namespace "$MONGODB_APP_NAMESPACE" \
  --from-literal="MONGODB_URL=${MONGODB_URL}" \
  --from-literal="SECRET_KEY=${SECRET_KEY}" \
  --dry-run=client \
  -o yaml |
kubectl apply -f -

kubectl get namespace \
  gatekeeper-system \
  "$MONGODB_APP_NAMESPACE"

kubectl get serviceaccount \
  aws-load-balancer-controller \
  --namespace kube-system \
  -o jsonpath='{.metadata.annotations.eks\.amazonaws\.com/role-arn}{"\n"}'

helm list --namespace gatekeeper-system
kubectl get constrainttemplates
kubectl get constraints
helm list --namespace kube-system
kubectl rollout status deployment/aws-load-balancer-controller \
  --namespace kube-system \
  --timeout=180s
