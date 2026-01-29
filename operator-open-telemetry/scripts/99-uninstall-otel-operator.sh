#!/usr/bin/env bash
set -euo pipefail

# Remove o OpenTelemetry Operator instalado via Helm.

ROOT_DIR="/home/renato/projetos/pessoal/demo-java-glow-root/operator-open-telemetry"
HELM="${ROOT_DIR}/tools/helm/helm"

RELEASE_NAME="${RELEASE_NAME:-otel-operator}"
NAMESPACE="${NAMESPACE:-opentelemetry-operator-system}"

if [[ ! -x "${HELM}" ]]; then
  echo "Helm não encontrado em ${HELM}. Rode scripts/00-download-helm.sh primeiro." >&2
  exit 1
fi

echo "Removendo release '${RELEASE_NAME}' do namespace '${NAMESPACE}'..."
"${HELM}" uninstall "${RELEASE_NAME}" --namespace "${NAMESPACE}" || true

echo "Observação: CRDs podem permanecer dependendo do chart e do cluster."
echo "OK"


