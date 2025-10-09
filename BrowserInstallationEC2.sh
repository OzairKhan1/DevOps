#!/usr/bin/env bash
set -euo pipefail

# Lightweight GUI + XRDP + Epiphany installer for Ubuntu (22.04+)
# - Installs LXDE (lightweight desktop), xrdp, epiphany-browser
# - Creates a 1GB swapfile if none exists (optional)
# - Configures XRDP to start LXDE for the target user
#
# Usage:
#   sudo ./script.sh
# Optional env variables:
#   USERNAME (default: ubuntu)
#   PASSWORD (optional - if provided, sets the user's password non-interactively)
#   SWAP_MB (default: 1024)
#
# Notes:
#  - Script assumes an Ubuntu user exists (default "ubuntu"). Change USERNAME if different.
#  - After install, connect via RDP client to EC2 public IP on port 3389 using USERNAME and password.
#  - If you prefer XFCE instead of LXDE, change the PACKAGES variable (comment included).

### CONFIGURATION
USERNAME="${USERNAME:-ubuntu}"
PASSWORD="${PASSWORD:-}"          # if non-empty, script will set this as the user's passwd
SWAP_MB="${SWAP_MB:-1024}"        # swap size in MB
DEBIAN_FRONTEND=noninteractive

echo "=== Installer starting ==="
echo "Target user: ${USERNAME}"
echo "Swap size (MB): ${SWAP_MB}"
[ -n "$PASSWORD" ] && echo "Password will be set for user ${USERNAME}."

# Basic safety checks
if ! id "${USERNAME}" >/dev/null 2>&1; then
  echo "Error: user '${USERNAME}' does not exist. Create the user first or set USERNAME to an existing user."
  exit 2
fi

# Update & base installs
echo "-> Updating apt..."
apt-get update -y

echo "-> Installing core packages (dbus, policykit, xorg minimal) ..."
apt-get install -y --no-install-recommends \
  dbus-x11 policykit-1 xorgxrdp xserver-xorg-legacy x11-xserver-utils \
  ca-certificates curl wget gnupg

# Desktop packages (lightweight)
# LXDE is very light. If you prefer XFCE replace lxde-core with xfce4.
echo "-> Installing LXDE (lightweight desktop) and essential packages..."
apt-get install -y --no-install-recommends lxde-core lxterminal lxpanel

# XRDP
echo "-> Installing and enabling xrdp..."
apt-get install -y xrdp
systemctl enable xrdp
systemctl restart xrdp

# Browser: Epiphany (GNOME web) - you mentioned it's already installed; this ensures it is present.
echo "-> Installing Epiphany (GNOME Web) browser..."
apt-get install -y --no-install-recommends epiphany-browser

# Helpful extras (file manager, minimal sound support)
apt-get install -y --no-install-recommends pcmanfm xinit

# Ensure policykit and session manager present
apt-get install -y --no-install-recommends policykit-1

# Create or ensure .xsession to start LXDE for the user
USER_HOME="$(eval echo ~${USERNAME})"
XSESSION_FILE="${USER_HOME}/.xsession"

echo "-> Configuring XRDP session for user '${USERNAME}' (file: ${XSESSION_FILE})"
cat > "${XSESSION_FILE}" <<'EOF'
#!/bin/sh
# Start LXDE session for XRDP
export XDG_RUNTIME_DIR=/run/user/$(id -u)
if [ -x /usr/bin/startlxde ]; then
  exec startlxde
fi
# fallback to x-session-manager
exec /usr/bin/x-session-manager
EOF

chown "${USERNAME}:${USERNAME}" "${XSESSION_FILE}"
chmod 700 "${XSESSION_FILE}"

# Some systems require startwm.sh tweak - we will not overwrite system files.
# Instead, ensure ~/.xsession is honored by enabling "Xsession" use via PAM environment if needed.

# Create swap if none exists
if ! swapon --show | grep -q '^'; then
  echo "-> No active swap found. Creating a ${SWAP_MB}MB swapfile..."
  SWAPFILE=/swapfile
  fallocate -l "${SWAP_MB}M" "${SWAPFILE}" || dd if=/dev/zero of="${SWAPFILE}" bs=1M count="${SWAP_MB}"
  chmod 600 "${SWAPFILE}"
  mkswap "${SWAPFILE}"
  swapon "${SWAPFILE}"
  echo "${SWAPFILE} none swap sw 0 0" >> /etc/fstab
else
  echo "-> Swap exists already. Skipping swap creation."
fi

# Optional: set password for user if provided
if [ -n "${PASSWORD}" ]; then
  echo "-> Setting password for user ${USERNAME}."
  echo "${USERNAME}:${PASSWORD}" | chpasswd
fi

# Optional: allow RDP through UFW (if UFW is active). If UFW not installed we skip
if command -v ufw >/dev/null 2>&1; then
  ufw allow 3389/tcp || true
  echo "-> Allowed 3389/tcp in UFW (if UFW active)."
fi

# Minimize background services to save RAM
echo "-> Disabling snapd (if present) to save RAM (won't affect system if snap not installed)..."
if systemctl list-unit-files | grep -q snapd.service; then
  systemctl stop snapd.service || true
  systemctl disable snapd.service || true
fi

# Final cleanup
apt-get autoremove -y
apt-get clean

echo "-> Finished installation steps."

# Provide user instructions
cat <<EOF

=== Setup completed ===

1. Connect with an RDP client (Windows: Remote Desktop, Mac: Microsoft Remote Desktop).
   - Host: <EC2_PUBLIC_IP> (use your EC2 public IP)
   - Port: 3389
   - Username: ${USERNAME}
   - Password: ${PASSWORD:-<use SSH password or set PASSWORD env before running the script>}

2. After login you should see the LXDE desktop. Launch Epiphany (called "Web" or "Epiphany") from the menu, or run:
   epiphany-browser &

3. If you see a blank/black screen on RDP:
   - Make sure you log in with the same username that ran this script (not root).
   - Reboot the instance: sudo reboot
   - If still blank, try creating /home/${USERNAME}/.xsession manually with "startlxde" (script already creates it).

4. To remove swap later: sudo swapoff /swapfile && rm /swapfile && sed -i '/\\/swapfile/d' /etc/fstab

Notes:
- This script keeps the environment minimal for 1GB RAM instances (t2.micro). Avoid running heavy sites or many tabs.
- If Epiphany performs poorly on a particular page, try using "epiphany-browser --profile" or switch to a comparably light browser (midori or epiphany alternative).

EOF

echo "=== All done ==="
