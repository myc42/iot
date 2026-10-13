#!/bin/bash
set -Eeuo pipefail

trap 'echo "ERREUR : échec à la ligne $LINENO. Arrêt du script." >&2' ERR

echo "======================================"
echo " CONFIGURATION K3S - macoulibS"
echo "======================================"

PROJECT_DIR="/home/vagrant/projet"
# /vagrant = dossier du Vagrantfile (p2/macoulib), les YAML sont dans object_k3s
CONF_DIR="/vagrant/object_k3s"
NODE_IP="192.168.56.110"
DEPLOYMENTS="app1-deployment app2-deployment app3-deployment"

# 1. Vérifier que K3s est opérationnel
echo "=== 1. Vérification de K3s ==="

if ! systemctl is-active --quiet k3s; then
    echo "ERREUR : le service K3s n'est pas actif."
    exit 1
fi

sudo k3s kubectl wait --for=condition=Ready node --all --timeout=120s
sudo k3s kubectl get nodes -o wide

# 2. Créer le dossier du projet
echo "=== 2. Préparation du projet ==="

mkdir -p "$PROJECT_DIR"

# 3. Copier les fichiers Kubernetes
echo "=== 3. Copie des fichiers YAML ==="

for file in deployment.yaml service.yaml ingress.yaml; do
    if [ ! -f "$CONF_DIR/$file" ]; then
        echo "ERREUR : fichier $CONF_DIR/$file introuvable."
        echo "Contenu de /vagrant :"
        ls -R /vagrant | head -n 40
        exit 1
    fi

    cp "$CONF_DIR/$file" "$PROJECT_DIR/"
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

K3S_IMAGES=$(sudo k3s crictl images)
echo "$K3S_IMAGES"

for image in projet-app1 projet-app2 projet-app3; do
    if ! echo "$K3S_IMAGES" | grep -F "$image" >/dev/null; then
        echo "ERREUR : image '$image' absente de K3s."
        exit 1
    fi
done

# 6. Déployer les applications
echo "=== 6. Déploiement des applications ==="

sudo k3s kubectl apply -f deployment.yaml

echo "=== Attente des Deployments ==="
for d in $DEPLOYMENTS; do
    sudo k3s kubectl rollout status "deployment/$d" --timeout=120s
done

echo "=== Vérification des Deployments ==="
sudo k3s kubectl get deployments

echo "=== Vérification des Pods ==="
sudo k3s kubectl get pods

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

# 9. Tests de routage (informatifs : n'arrêtent pas le script)
echo "=== 9. Tests de routage ==="

# Traefik (l'Ingress Controller de K3s) est installé par un job Helm :
# son Deployment peut ne pas exister tout de suite, on attend d'abord qu'il apparaisse
echo "--- Attente de Traefik ---"
for _ in $(seq 1 90); do
    if sudo k3s kubectl -n kube-system get deployment traefik >/dev/null 2>&1; then
        break
    fi
    sleep 2
done
sudo k3s kubectl -n kube-system rollout status deployment/traefik --timeout=180s || true
sleep 5

echo "--- Host: app1.com (attendu : app1) ---"
curl -s --max-time 10 -H "Host: app1.com" "http://$NODE_IP" | grep -o "Bienvenue dans app[0-9]" || echo "pas de réponse"

echo "--- Host: app2.com (attendu : app2) ---"
curl -s --max-time 10 -H "Host: app2.com" "http://$NODE_IP" | grep -o "Bienvenue dans app[0-9]" || echo "pas de réponse"

echo "--- Sans Host (attendu : app3) ---"
curl -s --max-time 10 "http://$NODE_IP" | grep -o "Bienvenue dans app[0-9]" || echo "pas de réponse"

echo "--- Host: nimportequoi.com (attendu : app3) ---"
curl -s --max-time 10 -H "Host: nimportequoi.com" "http://$NODE_IP" | grep -o "Bienvenue dans app[0-9]" || echo "pas de réponse"

echo "======================================"
echo " SUCCÈS : CONFIGURATION TERMINÉE"
echo "======================================"