#!/usr/bin/env bash
set -euo pipefail
TMP=$(mktemp -d)
git clone --depth 1 https://github.com/dogukanozdemir/golang-todo-mongodb "$TMP/upstream"
rsync -a --delete --exclude .git "$TMP/upstream/" ./
python3 - <<'APP_PATCH'
from pathlib import Path
p = Path("main.go")
if p.exists():
    s = p.read_text()
    s = s.replace('err := godotenv.Load(".env")', '_ = godotenv.Load(".env")')
    p.write_text(s)
APP_PATCH
