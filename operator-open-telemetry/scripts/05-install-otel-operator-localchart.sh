#!/usr/bin/env bash
set -euo pipefail

# Instala o OpenTelemetry Operator usando o chart local baixado em `charts/opentelemetry-operator`.

ROOT_DIR="/home/renato/projetos/pessoal/demo-java-glow-root/operator-open-telemetry"

HELM_LOCAL="${ROOT_DIR}/tools/helm/helm"
if [[ -x "${HELM_LOCAL}" ]]; then
  HELM="${HELM_LOCAL}"
else
  HELM="helm"
fi

RELEASE_NAME="${RELEASE_NAME:-otel-operator}"
NAMESPACE="${NAMESPACE:-opentelemetry-operator-system}"

CHART_DIR="${ROOT_DIR}/charts/opentelemetry-operator"
VALUES="${ROOT_DIR}/helm/opentelemetry-operator/values.yaml"

if [[ ! -d "${CHART_DIR}" ]]; then
  echo "Chart local não encontrado em ${CHART_DIR}" >&2
  echo "Rode primeiro: ${ROOT_DIR}/scripts/03-pull-otel-operator-chart.sh" >&2
  exit 1
fi

if [[ ! -f "${VALUES}" ]]; then
  echo "values.yaml não encontrado em ${VALUES}" >&2
  exit 1
fi

echo "Instalando/atualizando OpenTelemetry Operator (chart local) em ${NAMESPACE}..."
"${HELM}" upgrade --install "${RELEASE_NAME}" "${CHART_DIR}" \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  --values "${VALUES}"

echo "OK: verifique:"
echo "kubectl -n ${NAMESPACE} get deploy,po,svc"


