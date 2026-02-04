#!/usr/bin/env bash
set -euo pipefail

# Baixa e descompacta o Helm (client) para dentro do repositório, evitando
# dependência de pacotes do SO.
#
# Fonte oficial: https://github.com/helm/helm/releases
# Binários: https://get.helm.sh/

ROOT_DIR="/home/renato/projetos/pessoal/demo-java-glow-root/operator-open-telemetry"
TOOLS_DIR="${ROOT_DIR}/tools/helm"

# Troque se quiser fixar outra versão (recomendado em produção)
HELM_VERSION="${HELM_VERSION:-v3.14.4}"

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

case "${ARCH}" in
  x86_64) ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) echo "Arquitetura não suportada: ${ARCH}" >&2; exit 1 ;;
esac

TARBALL="helm-${HELM_VERSION}-${OS}-${ARCH}.tar.gz"
URL="https://get.helm.sh/${TARBALL}"

mkdir -p "${TOOLS_DIR}"

tmp_dir="$(mktemp -d)"
cleanup() { rm -rf "${tmp_dir}"; }
trap cleanup EXIT

echo "Baixando Helm ${HELM_VERSION} (${OS}/${ARCH})..."
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "${URL}" -o "${tmp_dir}/${TARBALL}"
elif command -v wget >/dev/null 2>&1; then
  wget -qO "${tmp_dir}/${TARBALL}" "${URL}"
else
  echo "Precisa de curl ou wget para baixar o Helm." >&2
  exit 1
fi

tar -xzf "${tmp_dir}/${TARBALL}" -C "${tmp_dir}"

install -m 0755 "${tmp_dir}/${OS}-${ARCH}/helm" "${TOOLS_DIR}/helm"

echo "OK: Helm instalado em ${TOOLS_DIR}/helm"
echo "Teste: ${TOOLS_DIR}/helm version"


