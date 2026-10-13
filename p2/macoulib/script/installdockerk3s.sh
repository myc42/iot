#!/bin/bash
set -euo pipefail

echo "=== Mise à jour de Valgrand ==="

# Vérification des droits
if [ "$EUID" -ne 0 ]; then
    echo "Erreur : lance le script avec sudo."
    exit 1
fi

# Mise à jour du système (Debian/Ubuntu)
apt-get update
apt-get upgrade -y

# Installation des dépendances
apt-get install -y curl ca-certificates

# Installation de K3s
if ! command -v k3s >/dev/null 2>&1; then
    echo "=== Installation de K3s ==="
    curl -sfL https://get.k3s.io | sh -
else
    echo "K3s est déjà installé."
fi

# Installation de Docker
if ! command -v docker >/dev/null 2>&1; then
    echo "=== Installation de Docker ==="
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sh /tmp/get-docker.sh
    rm -f /tmp/get-docker.sh
else
    echo "Docker est déjà installé."
fi

# Activation des services
systemctl enable --now docker
systemctl enable --now k3s

# Ajout de l'utilisateur vagrant au groupe Docker
if id vagrant >/dev/null 2>&1; then
    usermod -aG docker vagrant
    echo "Utilisateur vagrant ajouté au groupe Docker."
else
    echo "Utilisateur vagrant absent : ajout au groupe ignoré."
fi

# Vérification des installations
echo "=== Versions installées ==="
docker --version
docker compose version
k3s --version

# Construction des images du projet
PROJECT_DIR="/home/vagrant/projet"

if [ -d "$PROJECT_DIR" ]; then
    echo "=== Construction du projet ==="
    cd "$PROJECT_DIR"
    docker compose build
else
    echo "Répertoire $PROJECT_DIR introuvable."
    echo "Place le projet dans ce répertoire avant de lancer le build."
fi

echo "=== Opération terminée ==="
echo "Reconnecte-toi pour prendre en compte le groupe Docker."