#!/bin/bash
set -e

echo "Starting SSM Agent installation..."

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Cannot detect OS"
    exit 1
fi

echo "Detected OS: $OS"

case "$OS" in

    amzn)
        echo "Amazon Linux detected"
        yum install -y amazon-ssm-agent || true
        systemctl enable amazon-ssm-agent
        systemctl start amazon-ssm-agent
        ;;

    ubuntu|debian)
        echo "Ubuntu/Debian detected"
        apt-get update -y
        snap install amazon-ssm-agent --classic
        systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
        systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
        ;;

    centos|rhel)
        echo "CentOS/RHEL detected"
        yum install -y https://s3.amazonaws.com/amazon-ssm-us-east-1/latest/linux_amd64/amazon-ssm-agent.rpm
        systemctl enable amazon-ssm-agent
        systemctl start amazon-ssm-agent
        ;;

    *)
        echo "Unsupported OS. Install SSM Agent manually."
        exit 1
        ;;
esac

echo "SSM Agent installation completed."
