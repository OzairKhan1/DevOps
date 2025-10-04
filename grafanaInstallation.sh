#!/bin/bash
set -e

echo "==== Updating system ===="
sudo apt update -y

echo "==== Installing dependencies ===="
sudo apt install -y software-properties-common apt-transport-https wget

echo "==== Adding Grafana repository ===="
sudo mkdir -p /usr/share/keyrings/
sudo wget -q -O /usr/share/keyrings/grafana.key https://packages.grafana.com/gpg.key
echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list

echo "==== Installing Grafana ===="
sudo apt update
sudo apt install grafana -y

echo "==== Enabling and starting Grafana service ===="
sudo systemctl daemon-reload
sudo systemctl enable grafana-server
sudo systemctl start grafana-server

# OPTIONAL: Auto-provision Prometheus as a data source
PROM_URL="http://localhost:9090"
PROVISION_DIR="/etc/grafana/provisioning/datasources"

echo "==== Configuring Prometheus as default Grafana data source ===="
sudo mkdir -p $PROVISION_DIR

sudo tee ${PROVISION_DIR}/prometheus.yml > /dev/null <<EOF
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    orgId: 1
    url: ${PROM_URL}
    basicAuth: false
    isDefault: true
    editable: true
EOF

echo "==== Restarting Grafana to load new data source ===="
sudo systemctl restart grafana-server

echo
echo "✅ Grafana installation completed successfully!"
echo "Access Grafana at: http://<EC2-Public-IP>:3000"
echo "Default login: admin / admin"
echo "Prometheus data source has been pre-configured."
