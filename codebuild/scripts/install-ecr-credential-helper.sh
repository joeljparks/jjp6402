#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-v0.12.0}"
AWS_ACCOUNT_ID_ARG="${2:?AWS account ID is required}"
AWS_REGION_ARG="${3:?AWS region is required}"

ARCH_RAW="$(uname -m)"
case "$ARCH_RAW" in
  x86_64|amd64)
    ARCH="amd64"
    ;;
  aarch64|arm64)
    ARCH="arm64"
    ;;
  *)
    echo "Unsupported architecture: ${ARCH_RAW}" >&2
    exit 1
    ;;
esac

VERSION_RAW="${VERSION#v}"
REGISTRY="${AWS_ACCOUNT_ID_ARG}.dkr.ecr.${AWS_REGION_ARG}.amazonaws.com"
URL="https://amazon-ecr-credential-helper-releases.s3.us-east-2.amazonaws.com/${VERSION_RAW}/linux-${ARCH}/docker-credential-ecr-login"

curl --fail --location --show-error --silent --retry 3 --retry-delay 2 \
  -o /usr/local/bin/docker-credential-ecr-login \
  "$URL"

chmod +x /usr/local/bin/docker-credential-ecr-login

docker-credential-ecr-login version || true

mkdir -p "$HOME/.docker"
cat > "$HOME/.docker/config.json" <<JSON
{
  "credHelpers": {
    "${REGISTRY}": "ecr-login"
  }
}
JSON

echo "Configured Docker credential helper for ${REGISTRY}."
