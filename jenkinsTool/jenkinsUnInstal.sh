#!/bin/bash
# ==========================================================
#  Jenkins Uninstallation Script (APT-based Installation)
#  Tested on Ubuntu / Debian systems
# ==========================================================

echo "🔹 Stopping Jenkins service..."
sudo systemctl stop jenkins 2>/dev/null || true
sudo systemctl disable jenkins 2>/dev/null || true

echo "🔹 Removing Jenkins package..."
sudo apt remove --purge -y jenkins

echo "🔹 Cleaning up leftover Jenkins directories..."
sudo rm -rf /var/lib/jenkins
sudo rm -rf /var/log/jenkins
sudo rm -rf /etc/default/jenkins
sudo rm -rf /etc/systemd/system/jenkins.service

echo "🔹 Reloading systemd..."
sudo systemctl daemon-reload
sudo systemctl reset-failed

echo "🔹 Removing Jenkins repo and key (optional)..."
sudo rm -f /usr/share/keyrings/jenkins-keyring.asc
sudo rm -f /etc/apt/sources.list.d/jenkins.list
sudo apt update -y

echo "🔹 Checking Jenkins service status..."
if systemctl status jenkins &>/dev/null; then
    echo "⚠️  Jenkins service still exists. Please check manually."
else
    echo "✅ Jenkins successfully uninstalled!"
fi

echo "🔹 Checking if port 8080 is now free..."
if sudo lsof -i :8080 &>/dev/null; then
    echo "⚠️ Port 8080 still in use. Check for other services."
else
    echo "✅ Port 8080 is now free."
fi
