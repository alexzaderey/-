#!/bin/bash
set -u
ROOT="/opt/zalex"
VENV="$ROOT/venv"
APP="$ROOT/app"
ENV="$ROOT/zalex.env"
pass=0; fail=0
check(){ if eval "$2" >/dev/null 2>&1; then echo "[PASS] $1"; pass=$((pass+1)); else echo "[FAIL] $1"; fail=$((fail+1)); fi; }
check "root structure" "test -d $ROOT/storage/docs && test -d $ROOT/storage/knowledge/chroma"
check "python venv" "test -x $VENV/bin/python3"
check "Zalex package" "test -f $APP/zalex/__init__.py"
check "Tesseract" "command -v tesseract"
check "Tesseract Ukrainian data" "tesseract --list-langs | grep -qx ukr"
check "Python dependencies" "$VENV/bin/python3 -c 'import pypdf,pytesseract,PIL,chromadb,watchdog,fastapi,uvicorn'"
check "Experience DB" "test -f $ROOT/storage/experience/experience.sqlite"
check "Franki health" "curl -fsS --max-time 5 ${FRANKI_BASE_URL:-http://10.0.0.2:8080}/health"
check "Franki tokenizer" "curl -fsS --max-time 10 -H 'Content-Type: application/json' -d '{\"content\":\"2+2\"}' ${FRANKI_BASE_URL:-http://10.0.0.2:8080}/tokenize | grep -q tokens"
check "watcher service" "systemctl is-enabled zalex-watcher.service"
check "api service" "systemctl is-enabled zalex-api.service"
echo "Summary: PASS=$pass FAIL=$fail"
test "$fail" -eq 0
