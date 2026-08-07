#!/usr/bin/env bash
set -euo pipefail

if ! command -v helm >/dev/null 2>&1; then
  echo "helm is required" >&2
  exit 1
fi

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is required" >&2
  exit 1
fi

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
helm repo update >/dev/null

helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --version 9.1.4 \
  --set configs.params.server\.insecure=true \
  --wait

kubectl apply -f gitops/bootstrap/root-app.yaml

echo "Argo CD installed."
echo "Applications: kubectl get applications -n argocd"
echo "UI: kubectl -n argocd port-forward svc/argocd-server 8080:80"
