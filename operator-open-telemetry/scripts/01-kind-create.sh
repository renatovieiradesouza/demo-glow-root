#!/usr/bin/env bash
set -euo pipefail

# Cria um cluster Kind local para validar a instalação do Operator antes do on-prem.

ROOT_DIR="/home/renato/projetos/pessoal/demo-java-glow-root/operator-open-telemetry"
KIND_CONFIG="${ROOT_DIR}/kind/kind-config.yaml"

KIND_CLUSTER_NAME="${KIND_CLUSTER_NAME:-otel}"

if ! command -v kind >/dev/null 2>&1; then
  echo "kind não encontrado no PATH. Instale o kind e tente novamente." >&2
  exit 1
fi

echo "Criando cluster Kind '${KIND_CLUSTER_NAME}' (se já existir, o kind vai falhar)..."
kind create cluster --name "${KIND_CLUSTER_NAME}" --config "${KIND_CONFIG}"

echo "OK: cluster Kind criado. Contexto atual:"
kubectl config current-context


