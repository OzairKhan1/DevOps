#!/bin/bash

set -e

echo "Initializing Kubernetes Control Plane..."

sudo kubeadm init \
  --pod-network-cidr=192.168.0.0/16

echo "Configuring kubectl..."

mkdir -p $HOME/.kube

sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config

sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "Installing Calico..."

kubectl apply -f \
https://raw.githubusercontent.com/projectcalico/calico/v3.30.3/manifests/calico.yaml

echo
echo "Waiting for Calico to start..."
sleep 30

echo
echo "Worker Join Command:"
kubeadm token create --print-join-command
