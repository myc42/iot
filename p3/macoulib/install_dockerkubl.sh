#!/usr/bin/env bash
set -euo pipefail

# Vérifier les privilèges sudo
if ! sudo -v; then
  echo "Erreur : sudo est nécessaire."
  exit 1
fi

# 1. Installer Docker
sudo apt-get update
sudo apt-get install -y ca-certificates curl

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

. /etc/os-release
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl enable --now docker

# 2. Installer kubectl
curl -fsSL https://dl.k8s.io/release/stable.txt -o /tmp/kubectl-version
KUBECTL_VERSION=$(cat /tmp/kubectl-version)
curl -fsSLO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm -f kubectl /tmp/kubectl-version

# 3. Installer k3d
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# 4. Autoriser l'utilisateur courant à utiliser Docker sans sudo
sudo usermod -aG docker "$USER"

# 5. Vérifications
docker --version
kubectl version --client
k3d version

echo "Installation terminée. Déconnecte-toi puis reconnecte-toi pour appliquer le groupe docker."
echo "Ensuite, crée un cluster avec : k3d cluster create mon-cluster"
