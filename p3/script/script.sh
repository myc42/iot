#!/bin/bash

# Arrêter le script en cas d'erreur
set -e

echo "================================================="
echo " Début de l'installation : Docker, kubectl, k3d  "
echo "================================================="

# Installation des prérequis de base
sudo apt-get update -y
sudo apt-get install -y curl apt-transport-https ca-certificates

# 1. Installation de Docker
echo "--- [1/3] Vérification et installation de Docker ---"
if ! command -v docker &> /dev/null; then
    echo "Installation de Docker via le script officiel..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    
    # Ajout de l'utilisateur courant au groupe docker pour éviter d'utiliser sudo
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo "✅ Docker installé."
else
    echo "✅ Docker est déjà installé."
fi

# 2. Installation de kubectl
echo "--- [2/3] Vérification et installation de kubectl ---"
if ! command -v kubectl &> /dev/null; then
    echo "Récupération de la dernière version stable de kubectl..."
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    
    # Rendre le binaire exécutable et le déplacer dans le PATH
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    echo "✅ kubectl installé."
else
    echo "✅ kubectl est déjà installé."
fi

# 3. Installation de k3d
echo "--- [3/3] Vérification et installation de k3d ---"
if ! command -v k3d &> /dev/null; then
    echo "Installation de k3d via le script officiel..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
    echo "✅ k3d installé."
else
    echo "✅ k3d est déjà installé."
fi

echo "================================================="
echo " Installation terminée ! Voici les versions :    "
echo "================================================="
docker --version
kubectl version --client --output=yaml | grep gitVersion || true
k3d --version

echo ""
echo "⚠️  Important : Pour utiliser Docker sans sudo, vous devez recharger les groupes de votre session."
echo "Exécutez cette commande maintenant :  newgrp docker"
echo "Ou déconnectez-vous / reconnectez-vous à votre session utilisateur."
