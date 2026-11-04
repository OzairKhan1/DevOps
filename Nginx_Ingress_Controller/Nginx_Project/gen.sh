# 1. Clean up the broken configurations
helm repo remove ingress-nginx
helm repo remove prometheus-community

# 2. Add the correct, official Helm repositories
helm repo add ingress-nginx https://github.io
helm repo add prometheus-community https://github.io

# 3. Download the actual chart indexes from the new URLs
helm repo update

