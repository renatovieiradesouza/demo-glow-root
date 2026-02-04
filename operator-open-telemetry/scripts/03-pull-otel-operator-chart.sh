#!/usr/bin/env bash
set -euo pipefail

# Baixa o chart do OpenTelemetry Operator para uma pasta local no repo,
# permitindo instalar "do repo baixo" (sem depender do download na hora do deploy).
#
# Fonte dos charts: https://open-telemetry.github.io/opentelemetry-helm-charts

ROOT_DIR="/home/renato/projetos/pessoal/demo-java-glow-root/operator-open-telemetry"

# Preferir Helm baixado localmente; se não existir, cai pro helm do PATH.
HELM_LOCAL="${ROOT_DIR}/tools/helm/helm"
if [[ -x "${HELM_LOCAL}" ]]; then
  HELM="${HELM_LOCAL}"
else
  HELM="helm"
fi

CHART_NAME="open-telemetry/opentelemetry-operator"
# Fixe a versão do chart (recomendado). Pode sobrescrever via env var.
CHART_VERSION="${OTEL_OPERATOR_CHART_VERSION:-0.102.0}"

DEST_DIR="${ROOT_DIR}/charts"

mkdir -p "${DEST_DIR}"

echo "Configurando repo Helm open-telemetry..."
"${HELM}" repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts >/dev/null 2>&1 || true
"${HELM}" repo update >/dev/null

echo "Baixando chart ${CHART_NAME} (version=${CHART_VERSION}) para ${DEST_DIR}..."
rm -rf "${DEST_DIR}/opentelemetry-operator"
"${HELM}" pull "${CHART_NAME}" --version "${CHART_VERSION}" --untar --untardir "${DEST_DIR}"

echo "OK: chart local em ${DEST_DIR}/opentelemetry-operator"
echo "Instale com: ${ROOT_DIR}/scripts/05-install-otel-operator-localchart.sh"


