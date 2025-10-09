#!/bin/bash
set -e

echo "🔹 Creating namespace 'argocd'..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

echo "🔹 Installing Argo CD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "⏳ Waiting for Argo CD pods to be ready..."
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

echo "✅ Argo CD installed successfully!"

echo "🔹 Exposing Argo CD server service on NodePort 30090 (not conflicting with Jenkins)..."
kubectl patch svc argocd-server -n argocd -p '{
  "spec": {
    "type": "NodePort",
    "ports": [
      {
        "port": 443,
        "targetPort": 8080,
        "nodePort": 30090
      }
    ]
  }
}'

echo "✅ Access the Argo CD UI at: https://<your-ec2-public-ip>:30090"

echo "🔹 Your initial admin password is:"
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d; echo
