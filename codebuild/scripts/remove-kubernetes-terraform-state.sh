#!/usr/bin/env bash
set -euo pipefail

# Kubernetes and Helm objects are intentionally managed by the environment pipeline
# with kubectl/helm after AWS infrastructure is applied. Remove legacy Terraform state
# entries so Terraform does not need a Kubernetes provider during AWS planning.
addresses=(
  "kubernetes_namespace_v1.tasky"
  "kubernetes_secret_v1.mongodb_app"
  "kubernetes_namespace.tasky"
  "kubernetes_secret.mongodb_app"
  "module.kubernetes_addons.kubernetes_namespace_v1.gatekeeper_system"
  "module.kubernetes_addons.kubernetes_service_account_v1.lbc"
  "module.kubernetes_addons.helm_release.gatekeeper"
  "module.kubernetes_addons.helm_release.aws_load_balancer_controller"
  "module.kubernetes_addons.kubernetes_namespace.gatekeeper_system"
  "module.kubernetes_addons.kubernetes_service_account.lbc"
)

for address in "${addresses[@]}"; do
  if terraform state list | grep -Fxq "$address"; then
    echo "Removing legacy Kubernetes/Helm state address: ${address}"
    terraform state rm "$address"
  fi
done
