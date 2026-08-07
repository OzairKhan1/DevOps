#!/bin/bash
set -e

echo "Initializing Kubernetes Control Plane..."
sudo kubeadm init \
  --pod-network-cidr=192.168.0.0/16

echo "Configuring kubectl..."
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "Downloading Calico manifest..."
curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.30.3/manifests/calico.yaml

echo "Patching Calico to use VXLAN instead of IPIP (OCI's Security Lists block IP-in-IP/protocol-4 by default; VXLAN uses standard UDP 4789, which is far easier to allow on OCI)..."
sed -i 's/# value: "Always"/value: "Never"/' calico.yaml
sed -i '/name: CALICO_IPV4POOL_IPIP/,/value:/ s/value: "Always"/value: "Never"/' calico.yaml
sed -i '/name: CALICO_IPV4POOL_VXLAN/,/value:/ s/value: "Never"/value: "Always"/' calico.yaml

echo "Installing Calico..."
kubectl apply -f calico.yaml

echo
echo "Waiting for Calico to start..."
sleep 30

echo
echo "Worker Join Command:"
kubeadm token create --print-join-command
