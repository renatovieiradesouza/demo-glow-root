#!/usr/bin/env bash
set -euo pipefail

# Instala cert-manager via Helm.
# O OpenTelemetry Operator precisa do cert-manager para gerenciar certificados/webhooks.

ROOT_DIR="/home/renato/projetos/pessoal/demo-java-glow-root/operator-open-telemetry"
HELM="${ROOT_DIR}/tools/helm/helm"

CERT_MANAGER_NAMESPACE="${CERT_MANAGER_NAMESPACE:-cert-manager}"
# Troque se quiser fixar outra versão
CERT_MANAGER_CHART_VERSION="${CERT_MANAGER_CHART_VERSION:-v1.14.6}"

if [[ ! -x "${HELM}" ]]; then
  echo "Helm não encontrado em ${HELM}. Rode scripts/00-download-helm.sh primeiro." >&2
  exit 1
fi

echo "Adicionando repo do cert-manager (jetstack) e atualizando..."
"${HELM}" repo add jetstack https://charts.jetstack.io >/dev/null
"${HELM}" repo update >/dev/null

echo "Instalando/atualizando cert-manager em namespace '${CERT_MANAGER_NAMESPACE}'..."
"${HELM}" upgrade --install cert-manager jetstack/cert-manager \
  --namespace "${CERT_MANAGER_NAMESPACE}" \
  --create-namespace \
  --version "${CERT_MANAGER_CHART_VERSION}" \
  --set crds.enabled=true

echo "OK: cert-manager aplicado. Aguarde os pods ficarem Ready:"
echo "kubectl -n ${CERT_MANAGER_NAMESPACE} get pods"


