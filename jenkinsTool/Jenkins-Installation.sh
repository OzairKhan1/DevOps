#!/bin/bash
set -ex

# Update packages
sudo apt update

# Install Java (required by Jenkins)
sudo apt install -y fontconfig openjdk-21-jre

# Verify Java
java -version

# Add Jenkins repository key
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key

# Add Jenkins repository
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] \
https://pkg.jenkins.io/debian-stable binary/" \
| sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Update repositories
sudo apt update

# Install Jenkins
sudo apt install -y jenkins

# Start Jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins
