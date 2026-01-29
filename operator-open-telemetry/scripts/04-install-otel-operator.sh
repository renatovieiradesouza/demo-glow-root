#!/usr/bin/env bash
set -euo pipefail

# Instala o OpenTelemetry Operator via Helm usando o values versionado no repo.
#
# Referência (Operator): https://opentelemetry.io/docs/platforms/kubernetes/operator/

ROOT_DIR="/home/renato/projetos/pessoal/demo-java-glow-root/operator-open-telemetry"
HELM="${ROOT_DIR}/tools/helm/helm"
VALUES="${ROOT_DIR}/helm/opentelemetry-operator/values.yaml"

RELEASE_NAME="${RELEASE_NAME:-otel-operator}"
NAMESPACE="${NAMESPACE:-opentelemetry-operator-system}"

if [[ ! -x "${HELM}" ]]; then
  echo "Helm não encontrado em ${HELM}. Rode scripts/00-download-helm.sh primeiro." >&2
  exit 1
fi

if [[ ! -f "${VALUES}" ]]; then
  echo "values.yaml não encontrado em ${VALUES}" >&2
  exit 1
fi

echo "Instalando/atualizando OpenTelemetry Operator (${RELEASE_NAME}) em namespace '${NAMESPACE}'..."
"${HELM}" upgrade --install "${RELEASE_NAME}" open-telemetry/opentelemetry-operator \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  --values "${VALUES}"

echo "OK: release aplicada. Verifique:"
echo "kubectl -n ${NAMESPACE} get deploy,po,svc"


