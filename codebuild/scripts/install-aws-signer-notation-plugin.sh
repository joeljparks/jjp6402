#!/usr/bin/env bash
set -euo pipefail
TMP=$(mktemp -d)
curl -fsSLo "$TMP/plugin.zip" "https://d2hvyiie56hcat.cloudfront.net/linux/amd64/installer.zip"
unzip -o "$TMP/plugin.zip" -d "$TMP"
bash "$TMP/install.sh"
notation plugin ls || true
