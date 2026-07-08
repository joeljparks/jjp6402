#!/usr/bin/env bash
set -euo pipefail
VERSION="$1"
curl -fsSLo /tmp/go.tar.gz "https://go.dev/dl/go${VERSION}.linux-amd64.tar.gz"
rm -rf /usr/local/go
tar -C /usr/local -xzf /tmp/go.tar.gz
ln -sf /usr/local/go/bin/go /usr/local/bin/go
ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt
