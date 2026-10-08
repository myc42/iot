#!/bin/bash

# Arrêter le script en cas d'erreur
set -e

echo "=== 1. Mise à jour du système et installation des prérequis ==="
sudo apt-get update
sudo apt-get install -y curl ca-certificates gnupg lsb-release

echo "=== 2. Installation de Docker ==="
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Permettre à l'utilisateur actuel d'utiliser Docker sans sudo
sudo usermod -aG docker $USER
echo "-> Docker installé avec succès."

echo "=== 3. Installation de kubectl ==="
KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl
echo "-> kubectl installé avec succès."

echo "=== 4. Installation de k3d ==="
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
echo "-> k3d installé avec succès."

echo "=== Installation terminée avec succès ! ==="
echo "⚠️  Important : Veuillez vous déconnecter puis vous reconnecter (ou exécuter 'newgrp docker') pour que les permissions Docker prennent effet."
