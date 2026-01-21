## demo-otel/app-demo-java

App Spring Boot + Postgres + **instrumentação automática** com **OpenTelemetry Java Agent**, rodando localmente via Docker Compose.

### Subir a stack local

```bash
cd demo-otel/app-demo-java
docker compose up --build
```

### Acessos

- **App**: `http://localhost:8080`
- **Jaeger UI**: `http://localhost:16686`

### Endpoints

- **Listar usuários**: `GET /users`
- **Cadastrar usuário**: `POST /users`

Body exemplo:

```json
{ "name": "Renato", "email": "renato@example.com" }
```

### OTLP (para a aplicação)

No `docker-compose.yml`, a app envia OTLP para o Collector:

- `OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4318`

O Collector exporta traces para o Jaeger (OTLP gRPC) e também loga no stdout.


