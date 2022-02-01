#!/bin/bash

echo "======= DOCKER INSTALLATION"
sudo apt-get remove docker docker-engine docker.io containerd runc

sudo apt-get update && sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o \
    /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io

echo "======= DOCKER : ADD $USER to docker usergroup"
sudo usermod -a -G docker "$USER"

echo "======= INSTALLATION OF microk8s channel 1.22/stable"
sudo snap install microk8s --classic --channel=1.22/stable

echo "======= MICROK8S : ADD $USER to microk8s usergroup"
sudo usermod -a -G microk8s "$USER"
sudo chown -f -R "$USER" ~/.kube

echo "======= MICROK8S waiting server to be ready"
sudo microk8s status --wait-ready

echo "======= MICROK8S: enable dns registry and istio"
sudo microk8s enable dns registry istio

echo "======= MICROK8S: configuring user session"
echo -e "\nalias kubectl='microk8s kubectl'" >> ~/.bash_aliases
# shellcheck disable=SC1090
source ~/.bash_aliases

echo "======= MICROK8S: exporting kubeconfig file"
cd "$HOME" || exit
mkdir -p .kube
cd .kube || exit
sudo microk8s config | sudo tee config
cd .. || exit

sudo microk8s kubectl get nodes

echo "======= INSTALL FINISHED ========="
echo "You can run the cloud-tools-image container with this command:"
echo "sudo docker run --privileged=true \\"
echo -e "\t-v /var/run/docker.sock:/var/run/docker.sock \\"
echo -e "\t-v ~/.aws:/root/.aws:ro -it --rm \\"
echo -e "\t-v ~/.config/gcloud:/root/.config/gcloud \\"
echo -e "\t-v ~/.azure:/root/.azure \\"
echo -e "\t-v ~/.kube:/root/.kube \\"
echo -e "\t-e FALCON_CLIENT_ID=\"\$FALCON_CLIENT_ID\" \\"
echo -e "\t-e FALCON_CLIENT_SECRET=\"\$FALCON_CLIENT_SECRET\" \\"
echo -e "\t-e FALCON_CLOUD=\"\$FALCON_CLOUD\" \\"
echo -e "\t-e FALCON_CID=\"\$FALCON_CID\" \\"
echo -e "\tquay.io/crowdstrike/cloud-tools-image"