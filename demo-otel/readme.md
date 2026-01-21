## PoC OpenTelemetry (Kind) — App + Collector + Tempo + Grafana + Prometheus

Este PoC sobe:

- **App Spring Boot + Postgres** (instrumentada com **OpenTelemetry Java Agent**)
- **OpenTelemetry Collector** (recebe OTLP da app, exporta traces para o **Tempo** e expõe métricas para o **Prometheus**)
- **Tempo** (tracing)
- **Prometheus** (métricas — incluindo JVM)
- **Grafana** (dashboards/datasources provisionados)

### Pré-requisitos

- `docker`
- `kind`
- `kubectl`
- (opcional) `curl`

---

## 1) Criar o cluster Kind (com node infra)

O cluster Kind precisa de um node com:

- `nodeSelector: infra=true`
- `taint: dedicated=infra:NoSchedule` (os pods já têm `toleration`)

Crie o cluster:

```bash
kind create cluster --config curso-argocd-poc-blue-green/kind.yaml
kubectl config use-context kind-otel-poc
```

Verifique nodes/labels/taints:

```bash
kubectl get nodes --show-labels
kubectl describe node | egrep -i "Taints:|infra=true"
```

---

## 2) Subir Grafana + Tempo + Prometheus

```bash
kubectl apply -k demo-otel/grafana
kubectl -n observability rollout restart deployment/grafana deployment/prometheus deployment/tempo
```

---

## 3) Subir o OTel Collector

```bash
kubectl apply -k demo-otel/instalar-collector-cluster
kubectl -n demo-otel rollout restart deployment/otel-collector
kubectl -n demo-otel rollout status deployment/otel-collector
```

---

## 4) Build da imagem da app e carregar no Kind

```bash
cd demo-otel/app-demo-java
docker build -t demo-otel-app-demo-java:local .
kind load docker-image demo-otel-app-demo-java:local --name otel-poc
```

---

## 5) Deploy da app + Postgres

```bash
kubectl apply -k demo-otel/app-demo-java/instalacao-k8s-manifestos
kubectl -n demo-otel-app rollout status deployment/postgres
kubectl -n demo-otel-app rollout status deployment/demo-otel-app
```

---

## 6) Acessos (port-forward)

Grafana:

```bash
kubectl -n observability port-forward svc/grafana 3000:3000
```

- `http://localhost:3000`

App:

```bash
kubectl -n demo-otel-app port-forward svc/demo-otel-app 8080:8080
```

- `http://localhost:8080/users`

---

## 7) Gerar tráfego e ver traces/métricas

Gerar requisições:

```bash
curl -s http://localhost:8080/users >/dev/null
curl -i http://localhost:8080/users/boom
```

No Grafana:

- **Traces (Tempo)**: Explore → datasource **Tempo** (procure pelo service `demo-otel-app-demo-java`)
- **JVM Metrics**: Dashboards → Browse → pasta **OTel** → **OTel - JVM Overview** (selecionar a app no dropdown)
- **Collector Metrics**: Dashboards → Browse → pasta **OTel** → **OpenTelemetry Collector** (selecionar job `otel-collector-internal`)

---

## Troubleshooting rápido

- Pods:

```bash
kubectl -n observability get pods
kubectl -n demo-otel get pods
kubectl -n demo-otel-app get pods
```

- Logs:

```bash
kubectl -n demo-otel logs deployment/otel-collector --tail=200
kubectl -n observability logs deployment/tempo --tail=200
kubectl -n demo-otel-app logs deployment/demo-otel-app --tail=200
kubectl -n demo-otel-app logs deployment/postgres --tail=200
```


