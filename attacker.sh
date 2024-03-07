#!/bin/bash

# update the ubuntu config to not popup service to update
echo "======= configuring ubuntu to not generate any popup during update ======="
sudo sed -i "/#\$nrconf{restart} = 'i';/s/.*/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf

echo "======= setting hostname and preparing kubernetes cluster_name"

export motd_text="Attacker"
# configure a default cluster name in case of bootstrap in any environment

# encounter environment ?
if [ -f /tmp/alias.txt ]; then
  hostname=$(cat /tmp/alias.txt)
  suffix=""
  if [ -f /tmp/profile.txt ]; then
    suffix="-$(cat /tmp/profile.txt)"
  fi
  sudo hostnamectl hostname "$hostname$suffix"
fi

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

echo "======= Preparing the attacker machine"

curl -sSL "https://raw.githubusercontent.com/CrowdStrike/detection-container/main/bin/evil/sample" -o /tmp/malware


echo "======= Update motd"

sudo chmod -x /etc/update-motd.d/10-help-text
sudo chmod -x /etc/update-motd.d/50*
sudo chmod -x /etc/update-motd.d/90-updates-available
sudo chmod -x /etc/update-motd.d/91*
sudo chmod -x /etc/update-motd.d/95*

sudo apt-get install -y figlet net-tools

sudo echo '#!/bin/bash' | sudo tee -a /etc/update-motd.d/11-logo
sudo -E echo "figlet '$motd_text'" | sudo tee -a /etc/update-motd.d/11-logo
sudo chmod +x /etc/update-motd.d/11-logo

echo "======= INSTALL FINISHED ========="

newgrp docker
