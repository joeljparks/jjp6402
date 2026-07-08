#!/usr/bin/env bash
set -euo pipefail
VERSION="$1"
RAW="${VERSION#v}"
curl -fsSLo /tmp/trivy.tar.gz "https://github.com/aquasecurity/trivy/releases/download/${VERSION}/trivy_${RAW}_Linux-64bit.tar.gz"
tar -xzf /tmp/trivy.tar.gz -C /tmp trivy
mv /tmp/trivy /usr/local/bin/trivy
chmod +x /usr/local/bin/trivy
