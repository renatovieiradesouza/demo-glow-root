## OpenTelemetry Collector (instalação simples)

Esta pasta instala um OpenTelemetry Collector **bem leve** (1 réplica) recebendo OTLP via:

- **gRPC**: `4317`
- **HTTP**: `4318`

Ele está configurado para **exportar para logs do próprio pod** (exporter `logging`) para você validar a ingestão rapidamente.

### Aplicar no cluster

```bash
kubectl apply -k demo-otel/instalar-collector-cluster
```

### Importante: reiniciar após mudar ConfigMap

O Kubernetes **não** reinicia o pod automaticamente quando você altera o `ConfigMap`.

Sempre que editar `10-configmap.yaml`, rode:

```bash
kubectl -n demo-otel rollout restart deployment/otel-collector
```

### Endpoint OTLP para suas aplicações no cluster

- **OTLP gRPC**: `otel-collector.demo-otel.svc.cluster.local:4317`
- **OTLP HTTP**: `http://otel-collector.demo-otel.svc.cluster.local:4318`

### Infra placement (infra nodes)

O `Deployment` já vem com:

- `tolerations`: `dedicated=infra:NoSchedule`
- `nodeSelector`: `infra=true`

### Ajustar exportação para um backend (opcional)

Edite `10-configmap.yaml` e troque/adicione um exporter (ex.: `otlp`, `prometheusremotewrite`, etc.) conforme o seu backend.


