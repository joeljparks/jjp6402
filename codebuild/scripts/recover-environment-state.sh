#!/usr/bin/env bash
set -euo pipefail

NAME_PREFIX="${NAME_PREFIX:-jjp6402}"
AWS_REGION="${AWS_REGION:-us-east-2}"
EKS_CLUSTER_NAME="${EKS_CLUSTER_NAME:-${NAME_PREFIX}-eks}"

is_managed() {
  terraform state show "$1" >/dev/null 2>&1
}

import_iam_instance_profile_if_present() {
  local address="module.iam.aws_iam_instance_profile.mongodb"
  local name="${NAME_PREFIX}-mongodb-profile"

  if is_managed "$address"; then
    echo "Terraform already manages ${address}."
    return 0
  fi

  if aws iam get-instance-profile --instance-profile-name "$name" >/dev/null 2>&1; then
    echo "Importing existing IAM instance profile ${name} into Terraform state."
    terraform import -input=false "$address" "$name" || true
  else
    echo "IAM instance profile ${name} does not exist yet."
  fi
}

prepare_kubeconfig_if_cluster_exists() {
  if aws eks describe-cluster --name "$EKS_CLUSTER_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
    aws eks update-kubeconfig --name "$EKS_CLUSTER_NAME" --region "$AWS_REGION" >/dev/null
    return 0
  fi

  return 1
}

uninstall_failed_helm_release() {
  local namespace="$1"
  local release="$2"

  if ! helm status "$release" -n "$namespace" >/tmp/${release}-helm-status.txt 2>/dev/null; then
    echo "Helm release ${namespace}/${release} does not exist."
    return 0
  fi

  local status
  status="$(helm status "$release" -n "$namespace" -o json 2>/dev/null | jq -r '.info.status // empty')"

  case "$status" in
    failed|pending-install|pending-upgrade|pending-rollback)
      echo "Removing failed or pending Helm release ${namespace}/${release} with status ${status}."
      helm uninstall "$release" -n "$namespace" || true
      ;;
    *)
      echo "Helm release ${namespace}/${release} status is ${status:-unknown}; leaving it in place."
      ;;
  esac
}

import_helm_release_if_present() {
  local address="$1"
  local namespace="$2"
  local release="$3"

  if is_managed "$address"; then
    echo "Terraform already manages ${address}."
    return 0
  fi

  if helm status "$release" -n "$namespace" >/dev/null 2>&1; then
    echo "Importing existing Helm release ${namespace}/${release} into Terraform state."
    terraform import -input=false "$address" "${namespace}/${release}" || true
  else
    echo "Helm release ${namespace}/${release} does not exist or was removed."
  fi
}

import_iam_instance_profile_if_present

if prepare_kubeconfig_if_cluster_exists; then
  uninstall_failed_helm_release "gatekeeper-system" "gatekeeper"
  uninstall_failed_helm_release "kube-system" "aws-load-balancer-controller"
  import_helm_release_if_present "module.kubernetes_addons.helm_release.gatekeeper" "gatekeeper-system" "gatekeeper"
  import_helm_release_if_present "module.kubernetes_addons.helm_release.aws_load_balancer_controller" "kube-system" "aws-load-balancer-controller"
else
  echo "EKS cluster ${EKS_CLUSTER_NAME} does not exist yet; skipping Helm release recovery."
fi
