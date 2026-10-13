#!/bin/bash
set -e

# 1. Installation de K3s Server
curl -sfL https://get.k3s.io | sh -s - server \
  --node-ip 192.168.56.110 \
  --flannel-iface eth1 \
  --write-kubeconfig-mode 644

# 2. Attendre que K3s initialise le dossier des manifests
mkdir -p /var/lib/rancher/k3s/server/manifests

# 3. Copier les manifests pour le deploiement automatique
cp -r /vagrant/manifest/* /var/lib/rancher/k3s/server/manifests/

# 4. Attente active : s'assurer que Traefik et les apps sont prets avant la fin du vagrant up
echo "En attente du demarrage complet de Traefik et des applications..."
kubectl rollout status deployment/traefik -n kube-system --timeout=90s
kubectl rollout status deployment/app1 --timeout=60s
kubectl rollout status deployment/app2 --timeout=60s
kubectl rollout status deployment/app3 --timeout=60s