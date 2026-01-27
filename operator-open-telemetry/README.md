# OpenTelemetry Operator (Kubernetes) — via Helm (Kind para teste)

Este diretório monta a **estrutura** para instalar o **OpenTelemetry Operator** via **Helm** em um cluster Kubernetes (on-prem) e inclui um **Kind local** para validação antes de ir para o ambiente real.

Referências:
- Documentação do Operator: `https://opentelemetry.io/docs/platforms/kubernetes/operator/`
- Documentação Helm Charts (Kubernetes): `https://opentelemetry.io/pt/docs/platforms/kubernetes/helm/`

## O que tem aqui

- `helm/opentelemetry-operator/values.yaml`: **values recomendado** (baseline) com comentários explicando cada configuração.
- `kind/kind-config.yaml`: configuração do cluster Kind local.
- `scripts/`: scripts para bootstrap (baixar Helm, criar Kind, instalar cert-manager e instalar o Operator).
- `tools/helm/`: destino do binário do Helm (baixado/descompactado pelos scripts).

## Pré-requisitos (máquina local)

- `kubectl`
- `kind` (para teste local)
- `curl` ou `wget`

> Observação: O OpenTelemetry Operator precisa do **cert-manager** no cluster para webhooks/certificados.

## Fluxo sugerido (Kind local) — **apenas quando formos instalar**

## Instalação no Kind (comandos diretos: copiar/colar)

> Pré-requisitos: `kubectl` e `helm` instalados na máquina (ou use os scripts do repo abaixo).

1) **Garanta que o `kubectl` está apontando para o Kind**

```bash
kubectl config current-context
kubectl get nodes -o wide
```

Se você **já tem** um cluster Kind rodando mas não tem o contexto no `kubectl`:

```bash
kind get clusters
# exemplo:
kind export kubeconfig --name otel
kubectl config use-context kind-otel
```

2) **Instale o cert-manager** (pré-requisito do Operator para webhooks/certificados)

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update

helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.14.6 \
  --set crds.enabled=true
```

Espere ficar Ready:

```bash
kubectl -n cert-manager get pods
```

3) **Adicione o repo Helm do OpenTelemetry**

```bash
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update
```

4) **Instale o OpenTelemetry Operator usando o `values.yaml` do repo**

```bash
helm upgrade --install otel-operator open-telemetry/opentelemetry-operator \
  --namespace opentelemetry-operator-system \
  --create-namespace \
  -f /home/renato/projetos/pessoal/demo-java-glow-root/operator-open-telemetry/helm/opentelemetry-operator/values.yaml
```

5) **Verificação rápida**

```bash
kubectl -n opentelemetry-operator-system get deploy,po,svc
kubectl get crd | grep -i opentelemetry
```

6) **Desinstalar (opcional)**

```bash
helm uninstall otel-operator -n opentelemetry-operator-system
```

## Instalação no Kind (usando os scripts deste repo)

1) Baixar e descompactar o Helm (binário local no repo):

```bash
/home/renato/projetos/pessoal/demo-java-glow-root/operator-open-telemetry/scripts/00-download-helm.sh
```

2) Criar cluster Kind:

```bash
/home/renato/projetos/pessoal/demo-java-glow-root/operator-open-telemetry/scripts/01-kind-create.sh
```

3) Instalar cert-manager:

```bash
/home/renato/projetos/pessoal/demo-java-glow-root/operator-open-telemetry/scripts/02-install-cert-manager.sh
```

4) Adicionar repo Helm do OpenTelemetry:

```bash
/home/renato/projetos/pessoal/demo-java-glow-root/operator-open-telemetry/scripts/03-helm-repos.sh
```

5) Instalar/atualizar o OpenTelemetry Operator com o `values` do repo:

```bash
/home/renato/projetos/pessoal/demo-java-glow-root/operator-open-telemetry/scripts/04-install-otel-operator.sh
```

6) Remover (se precisar):

```bash
/home/renato/projetos/pessoal/demo-java-glow-root/operator-open-telemetry/scripts/99-uninstall-otel-operator.sh
```

## Próximos passos (quando você disser “bora instalar”)

- Validar se o `values.yaml` atende seu on-prem (proxy, registry privado, tolerations/affinity).
- Rodar o fluxo no Kind e checar:
  - Pods do operator
  - CRDs do OpenTelemetry
  - Webhooks
  - Logs do controller-manager


