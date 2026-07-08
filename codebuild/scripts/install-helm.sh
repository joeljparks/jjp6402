#!/usr/bin/env bash
set -euo pipefail
VERSION="$1"
curl -fsSLo /tmp/helm.tar.gz "https://get.helm.sh/helm-${VERSION}-linux-amd64.tar.gz"
tar -xzf /tmp/helm.tar.gz -C /tmp
mv /tmp/linux-amd64/helm /usr/local/bin/helm
chmod +x /usr/local/bin/helm
