## App demo (Kubernetes)

Este kustomize instala:

- Postgres (PVC + Deployment + Service)
- App Spring Boot (Deployment + Service)

A app envia OTLP para o Collector já criado em `demo-otel/instalar-collector-cluster`:

- `otel-collector.demo-otel.svc.cluster.local:4318` (HTTP/protobuf)

### Pré-requisito: instalar o Collector no cluster

```bash
kubectl apply -k demo-otel/instalar-collector-cluster
```

### Build & push da imagem da app

Você precisa publicar a imagem para um registry acessível pelo cluster (ou usar um registry local).

Exemplo (ajuste o nome do registry):

```bash
cd demo-otel/app-demo-java
docker build -t demo-otel-app-demo-java:local .
```

Depois, ajuste `20-deployment.yaml` para apontar para a sua imagem (ex.: `registry.local/demo-otel-app-demo-java:1.0`).

### Aplicar a app no cluster

```bash
kubectl apply -k demo-otel/app-demo-java/instalacao-k8s-manifestos
```

### Acessar a app (port-forward)

```bash
kubectl -n demo-otel-app port-forward svc/demo-otel-app 8080:8080
```

Endpoints:

- `GET  /users`
- `POST /users` (JSON: `{ "name": "...", "email": "..." }`)
- `GET  /users/boom`


