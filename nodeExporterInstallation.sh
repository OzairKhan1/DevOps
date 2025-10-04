#!/bin/bash
set -e
sudo apt update -y
echo "=== Installing Node Exporter ==="

# Create node_exporter user
sudo useradd --no-create-home --shell /bin/false node_exporter || true

# Download Node Exporter (adjust version if needed)
VERSION="1.8.1"
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/node_exporter-${VERSION}.linux-amd64.tar.gz

# Extract and move binaries
tar xvf node_exporter-${VERSION}.linux-amd64.tar.gz
sudo mv node_exporter-${VERSION}.linux-amd64/node_exporter /usr/local/bin/

# Clean up
rm -rf node_exporter-${VERSION}.linux-amd64*
cd ~

# Set ownership
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

# Create systemd service
sudo bash -c 'cat <<EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF'

# Reload systemd, enable and start service
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

# Verify
if systemctl is-active --quiet node_exporter; then
  echo "✅ Node Exporter is running successfully on port 9100!"
else
  echo "❌ Node Exporter failed to start. Check logs: sudo journalctl -u node_exporter -e"
fi

# Open firewall (if using ufw)
if command -v ufw >/dev/null 2>&1; then
  sudo ufw allow 9100/tcp
  echo "🔓 Port 9100 opened for Prometheus scraping"
fi
