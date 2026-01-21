## Grafana + Tempo (tracing) - Kubernetes

Stack mínima para visualizar **traces** no Grafana via **Tempo**.
Agora também inclui **Prometheus** para testar **métricas (JVM)**.

### Deploy

```bash
kubectl apply -k demo-otel/grafana
kubectl apply -k demo-otel/instalar-collector-cluster
```

> O Collector exporta traces para o Tempo em `tempo.observability.svc.cluster.local:4317`.

### Acessar o Grafana (port-forward)

```bash
kubectl -n observability port-forward svc/grafana 3000:3000
```

Abra `http://localhost:3000` (está com login anônimo habilitado).

### Prometheus (opcional) - port-forward

```bash
kubectl -n observability port-forward svc/prometheus 9090:9090
```

Abra `http://localhost:9090` e verifique o target `otel-collector`.

### Gerar tráfego na app (port-forward)

```bash
kubectl -n demo-otel-app port-forward svc/demo-otel-app 8080:8080
curl -s http://localhost:8080/users >/dev/null
curl -i http://localhost:8080/users/boom
```

### Ver traces

- Grafana → **Explore** → datasource **Tempo**
- Use **Search** e filtre por service name: `demo-otel-app-demo-java`

### Ver métricas JVM

No `demo-otel/app-demo-java/instalacao-k8s-manifestos`, as métricas foram reativadas e o Java Agent está com runtime metrics habilitado.

- Grafana → **Explore** → datasource **Prometheus**
- Exemplos de queries (podem variar conforme conversão do OTel → Prometheus):
  - `process_runtime_jvm_memory_used_bytes`
  - `process_runtime_jvm_gc_duration_seconds_count`

### Dashboard pronto (JVM)

Aplicando a stack, o Grafana já provisiona um dashboard:

- **Dashboards → Browse → OTel → "OTel - JVM Overview"**

### Dashboard pronto (OTel Collector)

O dashboard `demo-otel/grafana/mode_dash.json` (otelcol_*) agora é provisionado automaticamente.

Para ele mostrar dados, o Prometheus precisa scrapar as **métricas internas** do collector em `:8888` (job `otel-collector-internal`).

- **Dashboards → Browse → OTel → "OpenTelemetry Collector"**
- No topo do dashboard, selecione o **Job**: `otel-collector-internal`


