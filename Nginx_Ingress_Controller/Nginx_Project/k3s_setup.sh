#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "===================================================="
echo " Starting K3s Installation on Ubuntu 18.04 VM"
echo "===================================================="

# 1. Update system certificates to fix modern HTTPS issues
echo "--> Updating system certificates..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo update-ca-certificates

# 2. Configure Firewall (UFW) for K3s
if command -v ufw >/dev/null 2>&1; then
    echo "--> Configuring UFW firewall rules..."
    sudo ufw allow 6443/tcp comment 'K3s API Server' || true
    sudo ufw allow 8472/udp comment 'K3s Flannel VXLAN' || true
fi

# 3. Download K3s installer script securely
# Using -k/--insecure allows downloading despite outdated local SSL roots
echo "--> Downloading K3s installer script..."
curl -k -sfL https://get.k3s.io -o install_k3s_provider.sh
chmod +x install_k3s_provider.sh

# 4. Install a version of K3s stable for older kernels
echo "--> Installing K3s..."
# We enforce an older stable branch (v1.26) optimized for older kernels
export INSTALL_K3S_VERSION="v1.26.15+k3s1"
export INSTALL_K3S_EXEC="--disable traefik"

./install_k3s_provider.sh

# Clean up installer script
rm install_k3s_provider.sh

# 5. Configure kubectl access for the current non-root user
echo "--> Configuring kubectl access for user: $USER"
mkdir -p $HOME/.kube
sudo cp /etc/rancher/k3s/k3s.yaml $HOME/.kube/config
sudo chown $USER:$USER $HOME/.kube/config
chmod 600 $HOME/.kube/config

# 6. Add Kubeconfig to bashrc environment variables permanently
if ! grep -q "KUBECONFIG" "$HOME/.bashrc"; then
    echo 'export KUBECONFIG=$HOME/.kube/config' >> $HOME/.bashrc
fi

echo "===================================================="
echo " K3s installation complete!"
echo " Please run: 'source ~/.bashrc' to refresh your terminal."
echo " Check cluster status using: 'kubectl get nodes'"
echo "===================================================="

