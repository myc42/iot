#!/usr/bin/env bash
# Build et push des images v1 et v2 sur Docker Hub.
# À placer dans le dossier apps/ (à côté des dossiers v1 et v2).
# Prérequis : docker login (une seule fois) et un dépôt Docker Hub public.
set -euo pipefail

DOCKER_USER="macoulib"
IMAGE="${DOCKER_USER}/mon-app"
VERSIONS=("v1" "v2")
# amd64 pour la VM Linux classique, arm64 pour un Mac Apple Silicon
PLATFORMS="linux/amd64,linux/arm64"
BUILDER="multiarch"

# Dossier du script : marche depuis n'importe quel endroit
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Docker doit tourner
if ! docker info >/dev/null 2>&1; then
  echo "Erreur : Docker ne tourne pas (ou tu n'as pas les droits)." >&2
  exit 1
fi

# Vérifications avant de construire
for VERSION in "${VERSIONS[@]}"; do
  if [ ! -f "${ROOT}/${VERSION}/Dockerfile" ]; then
    echo "Erreur : ${ROOT}/${VERSION}/Dockerfile introuvable (attention au D majuscule)." >&2
    exit 1
  fi
done

if cmp -s "${ROOT}/v1/index.html" "${ROOT}/v2/index.html"; then
  echo "Attention : v1/index.html et v2/index.html sont identiques."
fi

# Builder qui sait construire pour plusieurs architectures (créé une seule fois)
if ! docker buildx inspect "${BUILDER}" >/dev/null 2>&1; then
  docker buildx create --name "${BUILDER}" --driver docker-container >/dev/null
fi
docker buildx inspect --bootstrap "${BUILDER}" >/dev/null

# Build + push de chaque version
for VERSION in "${VERSIONS[@]}"; do
  echo "=== Build et push de ${IMAGE}:${VERSION} ==="
  docker buildx build \
    --builder "${BUILDER}" \
    --platform "${PLATFORMS}" \
    -t "${IMAGE}:${VERSION}" \
    --push \
    "${ROOT}/${VERSION}"
done

echo "=== Terminé ==="
echo "Vérifie les tags : https://hub.docker.com/r/${IMAGE}/tags"