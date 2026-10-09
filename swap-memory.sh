#!/bin/bash

set -e

SWAPFILE="/swapfile"
SWAPSIZE="2G"

echo "Creating 2 GB swap space..."

# Create swap file
sudo fallocate -l $SWAPSIZE $SWAPFILE

# Secure permissions
sudo chmod 600 $SWAPFILE

# Format as swap
sudo mkswap $SWAPFILE

# Enable swap
sudo swapon $SWAPFILE

# Make persistent across reboot
if ! grep -q "^$SWAPFILE " /etc/fstab; then
    echo "$SWAPFILE none swap sw 0 0" | sudo tee -a /etc/fstab
fi

echo
echo "Swap configured successfully."
echo
free -h
echo
swapon --show
