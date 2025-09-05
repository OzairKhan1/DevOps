# 1. Update packages
sudo apt update -y
sudo apt upgrade -y

# 2. Install Java (Jenkins needs Java 11 or 17)
sudo apt install -y fontconfig openjdk-17-jre

# 3. Add Jenkins repo key
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

# 4. Add Jenkins repository
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# 5. Install Jenkins
sudo apt update -y
sudo apt install -y jenkins

# 6. Start and enable Jenkins service
sudo systemctl enable jenkins
sudo systemctl start jenkins

# 7. Check status
sudo systemctl status jenkins
