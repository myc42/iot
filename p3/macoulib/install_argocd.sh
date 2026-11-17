#!/bin/bash
set -e

# Créer le namespace ArgoCD
kubectl create namespace argocd \
  --dry-run=client -o yaml | kubectl apply -f -

# Installer ArgoCD
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Attendre que les composants soient prêts
kubectl wait --for=condition=Ready pods \
  --all -n argocd --timeout=300s

  # Créer le namespace dev
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -

echo "Namespaces argocd et dev créés !"

echo "Installation ArgoCD terminée !"

# kubectl apply -f manifests/deployment.yaml
# kubectl apply -f manifests/service.yaml
# kubectl apply -f manifests/argocd.yaml
#kubectl get pods -n argocd
#kubectl get pods -n dev
# kubectl port-forward -n dev service/app1-service 8080:80
