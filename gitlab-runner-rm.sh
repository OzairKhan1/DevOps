#!/bin/bash

token="glrt-R-OdAsYYzTBAFo7q5mEhSGM6MQpvOjEKcDoxZndyenUKdDozCnU6b3VpM2cc.01.1o0jb9slg"

set -e

echo "=========================================="
echo " GitLab Runner - Clean Systemd Setup"
echo "=========================================="

# --------------------------------------------------
# 1. Stop and remove existing GitLab Runner
# --------------------------------------------------

echo "[1/7] Removing old GitLab Runner..."

sudo systemctl stop gitlab-runner 2>/dev/null || true
sudo systemctl disable gitlab-runner 2>/dev/null || true
sudo gitlab-runner uninstall 2>/dev/null || true

sudo pkill -f gitlab-runner 2>/dev/null || true

sudo rm -f /usr/local/bin/gitlab-runner
sudo rm -f /usr/bin/gitlab-runner

sudo rm -rf /etc/gitlab-runner
rm -rf /home/ubuntu/.gitlab-runner
sudo rm -rf /home/gitlab-runner/.gitlab-runner

sudo systemctl daemon-reload
