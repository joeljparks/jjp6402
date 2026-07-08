#!/usr/bin/env bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y jq curl unzip git ca-certificates gnupg lsb-release python3-pip tar gzip

if ! command -v aws >/dev/null 2>&1; then
  echo "AWS CLI v2 not found in CodeBuild image; installing AWS CLI v2."
  TMP_DIR=$(mktemp -d)
  curl -fsSLo "$TMP_DIR/awscliv2.zip" "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
  unzip -q "$TMP_DIR/awscliv2.zip" -d "$TMP_DIR"
  "$TMP_DIR/aws/install" --update
fi

aws --version
jq --version
curl --version | head -n 1
git --version
