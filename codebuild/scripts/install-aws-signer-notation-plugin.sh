#!/usr/bin/env bash
set -euo pipefail

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

TMP="$(mktemp -d)"
PKG="${TMP}/aws-signer-notation-cli_${ARCH}.deb"
URL="https://d2hvyiie56hcat.cloudfront.net/linux/${ARCH}/installer/deb/latest/aws-signer-notation-cli_${ARCH}.deb"

echo "Installing AWS Signer Notation package from official AWS package URL."
curl --fail --location --show-error --silent --retry 3 --retry-delay 2 -o "$PKG" "$URL"

dpkg -i -E "$PKG"

notation version
notation plugin ls
notation plugin ls | grep -q 'com.amazonaws.signer.notation.plugin'
