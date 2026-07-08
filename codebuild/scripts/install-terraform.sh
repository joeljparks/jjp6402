#!/usr/bin/env bash
set -euo pipefail
VERSION="$1"
curl -fsSLo /tmp/terraform.zip "https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_linux_amd64.zip"
unzip -o /tmp/terraform.zip -d /usr/local/bin
chmod +x /usr/local/bin/terraform
