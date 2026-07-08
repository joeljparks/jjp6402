#!/usr/bin/env bash
set -euo pipefail
VERSION="$1"
curl -fsSLo /tmp/notation.tar.gz "https://github.com/notaryproject/notation/releases/download/v${VERSION}/notation_${VERSION}_linux_amd64.tar.gz"
tar -xzf /tmp/notation.tar.gz -C /tmp notation
mv /tmp/notation /usr/local/bin/notation
chmod +x /usr/local/bin/notation
