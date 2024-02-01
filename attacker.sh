#!/bin/bash

# update the ubuntu config to not popup service to update
echo "======= configuring ubuntu to not generate any popup during update ======="
sudo sed -i "/#\$nrconf{restart} = 'i';/s/.*/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf

echo "======= DOCKER INSTALLATION"
sudo apt-get remove docker docker-engine docker.io containerd runc

sudo apt-get update && sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    jq \
    lsb-release

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io

echo "======= DOCKER : ADD $USER to docker usergroup"
sudo usermod -a -G docker "$USER"

echo "======= Update motd"

sudo chmod -x /etc/update-motd.d/10-help-text
sudo chmod -x /etc/update-motd.d/50*
sudo chmod -x /etc/update-motd.d/90-updates-available
sudo chmod -x /etc/update-motd.d/91*
sudo chmod -x /etc/update-motd.d/95*

sudo apt-get install -y figlet

sudo echo '#!/bin/bash' | sudo tee -a /etc/update-motd.d/11-logo
sudo echo 'figlet "Attacker"' | sudo tee -a /etc/update-motd.d/11-logo
sudo chmod +x /etc/update-motd.d/11-logo

echo "======= INSTALL FINISHED ========="


