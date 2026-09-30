#!/bin/bash
set -euo pipefail

echo "=== Автоматичне розгортання Zalex V10 ==="
TARGET_DIR="/opt/zalex"
APP_DIR="$TARGET_DIR/app"
STORAGE_DIR="$TARGET_DIR/storage"
LOGS_DIR="$TARGET_DIR/logs"
VENV_DIR="$TARGET_DIR/venv"
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Debian/Ubuntu hosts: install only missing OS prerequisites.
if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y python3 python3-venv python3-pip tesseract-ocr tesseract-ocr-ukr curl
fi

sudo mkdir -p "$APP_DIR" "$STORAGE_DIR/docs" "$STORAGE_DIR/knowledge/chroma" "$STORAGE_DIR/experience" "$STORAGE_DIR/processed" "$LOGS_DIR"
sudo chown -R "$USER:$USER" "$TARGET_DIR"

rm -rf "$APP_DIR/zalex"
cp -a "$CURRENT_DIR/zalex" "$APP_DIR/"
cp -a "$CURRENT_DIR/zalex.env.example" "$TARGET_DIR/zalex.env.example"
if [ -f "$CURRENT_DIR/experience.sqlite" ]; then cp -a "$CURRENT_DIR/experience.sqlite" "$STORAGE_DIR/experience/experience.sqlite"; fi

python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"
pip install --upgrade pip
if [ -d "$CURRENT_DIR/wheelhouse" ] && find "$CURRENT_DIR/wheelhouse" -maxdepth 1 -type f -name '*.whl' -print -quit | grep -q .; then
  pip install --no-index --find-links="$CURRENT_DIR/wheelhouse" -r "$CURRENT_DIR/requirements-offline.txt"
else
  pip install -r "$CURRENT_DIR/requirements-offline.txt"
fi

ENV_FILE="$TARGET_DIR/zalex.env"
if [ ! -f "$ENV_FILE" ]; then cp "$CURRENT_DIR/zalex.env.example" "$ENV_FILE"; fi

sudo tee /etc/systemd/system/zalex-watcher.service >/dev/null <<EOF
[Unit]
Description=Zalex Automatic Knowledge Ingestion Watcher
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$APP_DIR
EnvironmentFile=$ENV_FILE
ExecStart=$VENV_DIR/bin/python3 -m zalex.ingestion.watcher
Restart=always
RestartSec=5
StandardOutput=append:$LOGS_DIR/watcher.log
StandardError=append:$LOGS_DIR/watcher_error.log

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/zalex-api.service >/dev/null <<EOF
[Unit]
Description=Zalex Orchestrator API
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$APP_DIR
EnvironmentFile=$ENV_FILE
ExecStart=$VENV_DIR/bin/uvicorn zalex.api.server:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=5
StandardOutput=append:$LOGS_DIR/api.log
StandardError=append:$LOGS_DIR/api_error.log

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable zalex-watcher.service zalex-api.service
sudo systemctl restart zalex-watcher.service zalex-api.service

echo "=== Розгортання завершено ==="
echo "Документи: $STORAGE_DIR/docs"
echo "API:       http://<zalex-ip>:8000"
echo "Watcher:   systemctl status zalex-watcher.service"
echo "API:       systemctl status zalex-api.service"
