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

echo "======= INSTALLATION OF microk8s channel 1.27/stable"
sudo snap install microk8s --classic --channel=1.27/stable

echo "======= MICROK8S : ADD $USER to microk8s usergroup"
sudo usermod -a -G microk8s "$USER"
sudo chown -f -R "$USER" ~/.kube

echo "======= MICROK8S waiting server to be ready"
sudo microk8s status --wait-ready

echo "======= MICROK8S: enable dns registry and istio"
sudo microk8s enable dns registry istio helm

echo "======= MICROK8S: enable community"
sudo microk8s enable community

echo "======= MICROK8S: configuring user session"
echo "--- kubectl alias"
sudo echo "alias kubectl='microk8s kubectl'" >> /home/$USER/.bashrc
sudo echo "alias k='microk8s kubectl'" >> /home/$USER/.bashrc
echo "--- helm alias"
sudo echo "alias helm='microk8s helm'" >> /home/$USER/.bashrc
echo "--- kubectl completion"
sudo echo "source <(kubectl completion bash)" >> /home/$USER/.bashrc

#echo -e "\nalias kubectl='microk8s kubectl'" >> ~/.bash_aliases
# shellcheck disable=SC1090
#source ~/.bash_aliases

echo "======= KUBECTL: Download and configure kubectl"
#curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
#chmod +x ./kubectl
#sudo mv ./kubectl /usr/local/bin/kubectl

echo "======= MICROK8S: exporting kubeconfig file"
cd "$HOME"
mkdir -p .kube
echo "== generate the kubeconfig file"
sudo microk8s config | sudo tee .kube/config

echo "== remove excessive permissions on kubeconfig"
sudo chmod g-r "$HOME/.kube/config"
sudo chmod o-r "$HOME/.kube/config"
sudo chown $USER "$HOME/.kube/config"


random_suffix=$(openssl rand -hex 2)
cluster_name="k8s-cluster-${random_suffix}"

sudo microk8s stop
echo "======= MICROK8S: renamin the cluster to ${cluster_name}"
sudo sed -i "s/microk8s-cluster/${cluster_name}/g" /var/snap/microk8s/current/credentials/client.config
sed -i "s/microk8s-cluster/${cluster_name}/g" $HOME/.kube/config

sudo microk8s start

sudo microk8s kubectl get nodes

echo "======= Download additional tools"

echo "== check-creds"
target_arch=$(uname -p)
sudo wget "https://github.com/falcon-pioupiou/lab-check/releases/download/v0.0.1/check-creds-linux-${target_arch}" -O /usr/local/bin/check-api-creds
sudo chmod +x /usr/local/bin/check-api-creds

echo "== falcon-container-sensor-pull"
sudo wget "https://raw.githubusercontent.com/CrowdStrike/falcon-scripts/main/bash/containers/falcon-container-sensor-pull/falcon-container-sensor-pull.sh" -O /usr/local/bin/falcon-container-sensor-pull.sh
sudo chmod +x /usr/local/bin/falcon-container-sensor-pull.sh

echo "== K9s"
sudo wget -c https://github.com/derailed/k9s/releases/download/v0.31.7/k9s_Linux_amd64.tar.gz -O - | sudo tar xzvf - -C "/usr/local/bin"

echo "======= INSTALL FINISHED ========="

newgrp docker
