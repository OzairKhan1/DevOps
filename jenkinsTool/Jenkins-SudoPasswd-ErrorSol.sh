# This script securely automates granting the Jenkins user controlled, passwordless sudo access to essential system commands following industry best practices.

#!/bin/bash
set -euo pipefail

SUDOERS_FILE="/etc/sudoers.d/jenkins"

echo "[INFO] Creating sudoers file for Jenkins at $SUDOERS_FILE"

# Write rules (overwrites if already exists)
cat <<'EOF' | sudo tee $SUDOERS_FILE > /dev/null
jenkins ALL=(ALL) NOPASSWD: /usr/bin/apt-get, /usr/bin/apt, /usr/bin/systemctl, /bin/cp, /bin/mv
EOF

# Secure permissions
echo "[INFO] Setting owner and permissions"
sudo chown root:root $SUDOERS_FILE
sudo chmod 440 $SUDOERS_FILE

# Validate sudoers syntax
echo "[INFO] Validating sudoers file"
sudo visudo -cf $SUDOERS_FILE

if [ $? -eq 0 ]; then
    echo "[SUCCESS] Sudoers file for Jenkins installed correctly."
else
    echo "[ERROR] Invalid sudoers file, rolling back..."
    sudo rm -f $SUDOERS_FILE
    exit 1
fi
