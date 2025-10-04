#!/bin/bash
set -e

echo "==== Updating system ===="
sudo apt update && sudo apt upgrade -y

echo "==== Creating Prometheus user and directories ===="
sudo useradd --no-create-home --shell /bin/false prometheus || true
sudo mkdir -p /etc/prometheus /var/lib/prometheus

echo "==== Downloading Prometheus ===="
PROM_VERSION="2.54.1"
cd /tmp
wget -q https://github.com/prometheus/prometheus/releases/download/v${PROM_VERSION}/prometheus-${PROM_VERSION}.linux-amd64.tar.gz
tar xvf prometheus-${PROM_VERSION}.linux-amd64.tar.gz

cd prometheus-${PROM_VERSION}.linux-amd64

# Clean up old console directories if they exist
sudo rm -rf /etc/prometheus/consoles /etc/prometheus/console_libraries

echo "==== Installing Prometheus binaries and files ===="
sudo mv prometheus promtool /usr/local/bin/
sudo mv consoles console_libraries /etc/prometheus/
sudo mv prometheus.yml /etc/prometheus/

sudo chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus /usr/local/bin/prometheus /usr/local/bin/promtool

echo "==== Creating clean Prometheus configuration ===="
sudo tee /etc/prometheus/prometheus.yml > /dev/null <<'EOF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]

  - job_name: "node_exporter"
    static_configs:
      - targets: ["localhost:9100"]
EOF

echo "==== Creating Prometheus systemd service ===="
sudo tee /etc/systemd/system/prometheus.service > /dev/null <<'EOF'
[Unit]
Description=Prometheus Monitoring
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF

echo "==== Downloading and configuring Node Exporter ===="
sudo useradd --no-create-home --shell /bin/false node_exporter || true
NODE_VERSION="1.8.2"
cd /tmp
wget -q https://github.com/prometheus/node_exporter/releases/download/v${NODE_VERSION}/node_exporter-${NODE_VERSION}.linux-amd64.tar.gz
tar xvf node_exporter-${NODE_VERSION}.linux-amd64.tar.gz
sudo mv node_exporter-${NODE_VERSION}.linux-amd64/node_exporter /usr/local/bin/

sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<'EOF'
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

echo "==== Reloading and enabling services ===="
sudo systemctl daemon-reload
sudo systemctl enable prometheus node_exporter

echo "==== Checking Prometheus config syntax ===="
promtool check config /etc/prometheus/prometheus.yml || { echo "Prometheus config invalid!"; exit 1; }

echo "==== Starting Prometheus and Node Exporter ===="
sudo systemctl start prometheus node_exporter

sleep 2
sudo systemctl status prometheus --no-pager
sudo systemctl status node_exporter --no-pager

echo
echo "✅ Prometheus & Node Exporter successfully installed!"
echo "Prometheus: http://<Public-IP>:9090"
echo "Node Exporter: http://<Public-IP>:9100/metrics"
