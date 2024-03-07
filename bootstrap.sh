#!/bin/bash

# update the ubuntu config to not popup service to update
echo "======= configuring ubuntu to not generate any popup during update ======="
sudo sed -i "/#\$nrconf{restart} = 'i';/s/.*/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf

echo "======= setting hostname and preparing kubernetes cluster_name"

random_suffix=$(openssl rand -hex 2)
cluster_name="k8s-cluster-${random_suffix}"
motd_text="Lab"
# configure a default cluster name in case of bootstrap in any environment

# encounter environment ?
if [ -f /tmp/alias.txt ]; then
  hostname=$(cat /tmp/alias.txt)
  suffix=""
  cluster_name=$hostname
  motd_prefix="$(echo "Q3Jvd2RTdHJpa2U=" | base64 -d) "
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

echo "======= INSTALLATION OF microk8s channel 1.27/stable"
sudo snap install microk8s --classic --channel=1.27/stable

echo "======= MICROK8S : ADD $USER to microk8s usergroup"
sudo usermod -a -G microk8s "$USER"
sudo chown -f -R "$USER" ~/.kube

echo "======= MICROK8S waiting server to be ready"
sudo microk8s status --wait-ready

echo "======= MICROK8S: enable community"
sudo microk8s enable community

echo "======= MICROK8S: enable dns registry istio and traefik"
echo "--- enable dns"
sudo microk8s enable dns
echo "--- enable registry"
sudo microk8s enable registry
echo "--- enable istio"
sudo microk8s enable istio
echo "--- enable helm"
sudo microk8s enable helm
echo "--- enable traefik"
sudo microk8s enable traefik

echo "======= MICROK8S: configuring user session"
echo "--- kubectl alias"
sudo echo "alias kubectl='microk8s kubectl'" >> /home/$USER/.bash_aliases
sudo echo "alias k='microk8s kubectl'" >> /home/$USER/.bash_aliases
echo "--- helm alias"
sudo echo "alias helm='microk8s helm'" >> /home/$USER/.bash_aliases
echo "--- kubectl completion"
sudo echo "source <(kubectl completion bash)" >> /home/$USER/.bashrc
echo "--- k (alias) autocompletion"
sudo echo "complete -o default -F __start_kubectl k" >> /home/$USER/.bashrc
echo "--- helm autocompletion"
sudo echo "source <(helm completion bash)" >> /home/$USER/.bashrc

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

sudo microk8s stop
echo "======= MICROK8S: renaming the cluster to ${cluster_name}"
sudo sed -i "s/microk8s-cluster/${cluster_name}/g" /var/snap/microk8s/current/credentials/client.config
echo "--image-gc-low-threshold=95" | sudo tee -a /var/snap/microk8s/current/args/kubelet
echo "--image-gc-high-threshold=97" | sudo tee -a /var/snap/microk8s/current/args/kubelet
sudo sed -i "s/1Gi/100Mi/g" /var/snap/microk8s/current/args/kubelet
sed -i "s/microk8s-cluster/${cluster_name}/g" $HOME/.kube/config

sudo microk8s start

sudo microk8s kubectl get nodes

echo "======= Download additional tools"

echo "== check-creds"
target_arch=$(uname -p)
sudo wget "https://github.com/falcon-pioupiou/lab-check/releases/download/v0.0.1/check-creds-linux-${target_arch}" -O /usr/local/bin/check-api-creds
sudo chmod +x /usr/local/bin/check-api-creds

echo "== falcon-container-sensor-pull"
sudo wget "https://github.com/CrowdStrike/falcon-scripts/releases/download/v1.3.1/falcon-container-sensor-pull.sh" -O /usr/local/bin/falcon-container-sensor-pull.sh
sudo chmod +x /usr/local/bin/falcon-container-sensor-pull.sh

echo "== K9s"
sudo wget -c https://github.com/derailed/k9s/releases/download/v0.31.7/k9s_Linux_amd64.tar.gz -O - | sudo tar xzvf - -C "/usr/local/bin"

echo "== persist-creds"
sudo wget "https://raw.githubusercontent.com/falcon-pioupiou/sea-bootstrap/master/persist-creds" -O /usr/local/bin/persist-creds
sudo chmod +x /usr/local/bin/persist-creds

echo "======= Update motd"

sudo chmod -x /etc/update-motd.d/10-help-text
sudo chmod -x /etc/update-motd.d/50*
sudo chmod -x /etc/update-motd.d/90-updates-available
sudo chmod -x /etc/update-motd.d/91*
sudo chmod -x /etc/update-motd.d/95*

sudo apt-get install -y figlet

sudo echo '#!/bin/bash' | sudo tee -a /etc/update-motd.d/11-lab-logo
sudo -E echo 'figlet "$motd_prefix$motd_text"' | sudo tee -a /etc/update-motd.d/11-lab-logo
sudo chmod +x /etc/update-motd.d/11-lab-logo


echo "======= INSTALL FINISHED ========="


newgrp docker
