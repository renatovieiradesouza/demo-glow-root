#!/usr/bin/env bash
set -euo pipefail

# Adiciona os repositórios Helm necessários.

ROOT_DIR="/home/renato/projetos/pessoal/demo-java-glow-root/operator-open-telemetry"
HELM="${ROOT_DIR}/tools/helm/helm"

if [[ ! -x "${HELM}" ]]; then
  echo "Helm não encontrado em ${HELM}. Rode scripts/00-download-helm.sh primeiro." >&2
  exit 1
fi

echo "Adicionando repos Helm..."
"${HELM}" repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts >/dev/null

echo "Atualizando repos..."
"${HELM}" repo update >/dev/null

echo "OK: repos configurados"


