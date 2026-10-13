#!/bin/bash
set -Eeuo pipefail

trap 'echo "ERREUR : échec à la ligne $LINENO. Arrêt du script." >&2' ERR

echo "======================================"
echo " CONFIGURATION K3S - VM1"
echo "======================================"

PROJECT_DIR="/home/vagrant/projet"

# 1. Vérifier que K3s est opérationnel
echo "=== 1. Vérification de K3s ==="

if ! systemctl is-active --quiet k3s; then
    echo "ERREUR : le service K3s n'est pas actif."
    exit 1
fi

sudo k3s kubectl get nodes

# 2. Créer le dossier du projet
echo "=== 2. Préparation du projet ==="

mkdir -p "$PROJECT_DIR"

# 3. Copier les fichiers Kubernetes
echo "=== 3. Copie des fichiers YAML ==="

for file in service.yaml deployment.yaml ingress.yaml; do
    if [ ! -f "/vagrant/$file" ]; then
        echo "ERREUR : fichier /vagrant/$file introuvable."
        exit 1
    fi

    cp "/vagrant/$file" "$PROJECT_DIR/"
done

cd "$PROJECT_DIR"

# 4. Vérifier les images Docker
echo "=== 4. Vérification des images Docker ==="

for image in projet-app1 projet-app2 projet-app3; do
    if ! docker image inspect "$image" >/dev/null 2>&1; then
        echo "ERREUR : image Docker '$image' introuvable."
        echo "Construis d'abord les images avec docker compose build."
        exit 1
    fi
done

docker images

# 5. Importer les images dans K3s
echo "=== 5. Importation des images dans K3s ==="

docker save projet-app1 projet-app2 projet-app3 \
    | sudo k3s ctr images import -

# Vérifier les images importées
echo "=== Vérification des images K3s ==="

sudo k3s crictl images

for image in projet-app1 projet-app2 projet-app3; do
    if ! sudo k3s crictl images | grep -Fq "$image"; then
        echo "ERREUR : image '$image' absente de K3s."
        exit 1
    fi
done

# 6. Déployer les applications
echo "=== 6. Déploiement des applications ==="

sudo k3s kubectl apply -f deployment.yaml

echo "=== Vérification des Deployments ==="
sudo k3s kubectl get deployments

echo "=== Vérification des Pods ==="
sudo k3s kubectl get pods

# Attendre que les Deployments soient prêts
sudo k3s kubectl rollout status deployment --all \
    --timeout=120s

# 7. Déployer les Services
echo "=== 7. Déploiement des Services ==="

sudo k3s kubectl apply -f service.yaml

echo "=== Vérification des Services ==="
sudo k3s kubectl get svc

echo "=== Vérification des Endpoints ==="
sudo k3s kubectl get endpoints

# 8. Déployer l'Ingress
echo "=== 8. Déploiement de l'Ingress ==="

sudo k3s kubectl apply -f ingress.yaml

echo "=== Vérification de l'Ingress ==="
sudo k3s kubectl get ingress

echo "======================================"
echo " SUCCÈS : CONFIGURATION TERMINÉE"
echo "======================================"