#!/usr/bin/env bash
set -euo pipefail
VERSION="$1"
python3 -m pip install --no-cache-dir "checkov==${VERSION}"
