#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

NODE_IP="192.168.56.110"
PROJECT_DIR="/home/vagrant/projet"

echo "=== Mise à jour de Vagrant ==="

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

# Installation de K3s (mode server, lié à l'IP privée)
if ! command -v k3s >/dev/null 2>&1; then
    echo "=== Installation de K3s ==="

    # Détecte le nom de l'interface qui porte 192.168.56.110 (eth1, enp0s8...)
    IFACE=$(ip -o -4 addr show | awk -v ip="$NODE_IP" '$4 ~ ("^" ip "/") {print $2}')

    if [ -z "$IFACE" ]; then
        echo "Erreur : aucune interface ne porte l'IP $NODE_IP."
        echo "Vérifie le private_network dans le Vagrantfile."
        exit 1
    fi

    echo "Interface détectée pour $NODE_IP : $IFACE"

    curl -sfL https://get.k3s.io | \
        INSTALL_K3S_EXEC="server --write-kubeconfig-mode 644 --node-ip $NODE_IP --flannel-iface $IFACE" \
        sh -
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

# Attendre que l'API K3s réponde, puis que le noeud soit Ready
echo "=== Attente du noeud K3s ==="
for _ in $(seq 1 30); do
    if k3s kubectl get nodes >/dev/null 2>&1; then
        break
    fi
    sleep 2
done
k3s kubectl wait --for=condition=Ready node --all --timeout=120s
k3s kubectl get nodes -o wide

# Ajout de l'utilisateur vagrant au groupe Docker
if id vagrant >/dev/null 2>&1; then
    usermod -aG docker vagrant
    echo "Utilisateur vagrant ajouté au groupe Docker."

    # kubectl et alias k utilisables directement par vagrant (sans sudo)
    if ! grep -q KUBECONFIG /home/vagrant/.bashrc; then
        echo 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml' >> /home/vagrant/.bashrc
        echo 'alias k=kubectl' >> /home/vagrant/.bashrc
    fi
else
    echo "Utilisateur vagrant absent : configuration ignorée."
fi

# Vérification des installations
echo "=== Versions installées ==="
docker --version
docker compose version
k3s --version

# Construction des images du projet
if [ -d "$PROJECT_DIR" ]; then
    echo "=== Construction du projet ==="
    cd "$PROJECT_DIR"
    docker compose build
else
    echo "Erreur : répertoire $PROJECT_DIR introuvable."
    echo "created_3app.sh doit créer le projet avant ce script."
    exit 1
fi

echo "=== Opération terminée ==="
echo "Reconnecte-toi pour prendre en compte le groupe Docker."