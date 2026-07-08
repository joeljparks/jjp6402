#!/usr/bin/env bash
set -euo pipefail
VERSION="$1"
curl -fsSLo /usr/local/bin/kubectl "https://dl.k8s.io/release/${VERSION}/bin/linux/amd64/kubectl"
chmod +x /usr/local/bin/kubectl
