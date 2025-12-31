# AUTO-INSTRUMENTAÇÃO COM GLOWROOT – GUIA SIMPLES PARA DEVS

Este guia mostra como **ligar o Glowroot** em qualquer app Java 21 / Spring Boot **sem mudar código**:
apenas configurando o **Java Agent** e o `glowroot.properties`.  
Use este projeto como referência.

---

## Passo 1 – O que é auto‑instrumentação

- **Auto‑instrumentação** = anexar o `glowroot.jar` via `-javaagent` quando a JVM sobe.
- O Agent:
  - intercepta automaticamente **HTTP** (Spring Boot),
  - instrumenta **JDBC/JPA (Hibernate)**,
  - captura **erros/exceções**,
  - coleta métricas de **JVM**.
- Neste projeto, os dados vão para um **Glowroot Central** dedicado, não para a UI embedded (UI gerada dentro da app principal).

Arquivos importantes:

- `Dockerfile` – onde o Agent é baixado e ligado via `-javaagent`.
- `glowroot/glowroot.properties` – onde definimos `agent.id` e `collector.address` onde definimos o envios dos dados coletados.

---

## Passo 2 – Configurar o Agent na imagem (exemplo com Dockerfile)

Arquivo: `Dockerfile`

Trecho relevante:

```startLine:endLine:Dockerfile
FROM eclipse-temurin:21-jre AS runtime
WORKDIR /app

RUN apt-get update \
    && apt-get install -y curl unzip \
    && rm -rf /var/lib/apt/lists/*

# Versão mais nova do Glowroot Agent, compatível com Java 21
ENV GLOWROOT_VERSION=0.14.4

# Baixa e instala o Glowroot Agent (runtime)
RUN mkdir -p /glowroot \
    && curl -L -o /tmp/glowroot.zip https://github.com/glowroot/glowroot/releases/download/v${GLOWROOT_VERSION}/glowroot-${GLOWROOT_VERSION}-dist.zip \
    && unzip /tmp/glowroot.zip -d /tmp \
    && mv /tmp/glowroot/* /glowroot/ \
    && rm -rf /tmp/glowroot /tmp/glowroot.zip

# Configuração personalizada do Agent (agent.id) e da UI (admin.json)
COPY glowroot/glowroot.properties /glowroot/glowroot.properties
COPY glowroot/admin.json /glowroot/admin.json

COPY --from=build /workspace/target/demo-java-glowroot-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8080
EXPOSE 4000

ENTRYPOINT ["java", "-javaagent:/glowroot/glowroot.jar", "-jar", "/app/app.jar"]
```

**O que você precisa copiar para o seu serviço:**

1. Baixar o `glowroot-<versão>-dist.zip` (curl + unzip) e copiar o conteúdo para `/glowroot`.
2. Copiar um `glowroot.properties` adequado para `/glowroot/glowroot.properties`.
3. Iniciar a JVM com:
   - `-javaagent:/glowroot/glowroot.jar`
4. Vale destacar a recomendação para evitar fazer o download do agent no build, você pode deixar o pacote zipado no próprio projeto.

Esse padrão vale tanto para Docker quanto para qualquer outro ambiente
(systemd, script de shell, etc.): a única exigência é o `-javaagent`.

---

## Passo 3 – Configurar identidade e destino no `glowroot.properties`

Arquivo: `glowroot/glowroot.properties`

```startLine:endLine:glowroot/glowroot.properties
# Identificador deste backend na UI do Glowroot Central
agent.id=demo-java-backend

# Envia todos os dados para o Glowroot Central (collector) rodando em outro stack.
# Aqui usamos o hostname do serviço no network compartilhado de Docker Compose.
collector.address=glowroot-central:8181
collector.ssl=false
```

**Pontos importantes para o seu projeto:**

- **`agent.id`**  
  - Nome amigável do serviço na UI do Glowroot Central.  
  - Ex.: `orders-api`, `billing-service`, `identity-service`.

- **`collector.address`**  
  - Endereço do Glowroot Central (porta **8181**, que é o collector gRPC, não a UI).
  - Exemplo típico em ambiente dockerizado:
    - `collector.address=glowroot-central:8181`

---

## Passo 4 – Subir a aplicação com o Agent ligado

Com o `Dockerfile` e `glowroot.properties` já ajustados:

```bash
docker compose up --build
```

O que deve acontecer:

- O container da app sobe com:
  - Java 21
  - `-javaagent:/glowroot/glowroot.jar`
- Nos logs da app, você verá algo como:

```text
Glowroot version: 0.14.4 ...
agent id: demo-java-backend
connected to the central collector http://glowroot-central:8181, version 0.14.4 ...
```

Se aparecer essa linha de “connected to the central collector…”, o Agent está OK.

---

## Passo 5 – Gerar tráfego e validar no Glowroot Central

1. **Gerar tráfego no app demo**

```bash
curl http://localhost:8080/health
curl http://localhost:8080/users

# endpoints de erro (para ver entradas em Errors / Traces)
curl -i http://localhost:8080/users/boom
curl -i http://localhost:8080/users/db-error
```

2. **Abrir a UI do Glowroot Central**

- URL: `http://localhost:4000`
- Selecionar o agente: `demo-java-backend` (ou o `agent.id` que você usou).

3. **O que olhar na UI**

- **Transactions → Web**  
  - Latência e throughput de `/health`, `/users`, etc.
- **Traces**  
  - Traces individuais das chamadas (inclusive erros).
- **Errors**  
  - Os 500 gerados por `/users/boom` e `/users/db-error`.
- **SQL**  
  - Queries `SELECT` / `INSERT` na tabela `users` (JPA/Hibernate).
- **JVM**  
  - Heap, GC, threads, CPU.

---

## Passo 6 – Como aplicar esse padrão em outro serviço

Resumo para um novo serviço Java 21 / Spring Boot:

1. **Criar pasta `glowroot/`** no projeto com:
   - `glowroot/glowroot.properties` contendo:
     - `agent.id=<nome-do-servico>`
     - `collector.address=<host-do-central>:8181`

2. **Ajustar o Dockerfile (ou script de execução)** para:
   - Baixar e descompactar o Glowroot para `/glowroot`.
   - Iniciar a JVM com:
     - `-javaagent:/glowroot/glowroot.jar`

3. **Subir o serviço** e verificar nos logs:
   - Mensagem de conexão com o Central.

4. **Validar na UI do Central**:
   - Ver o novo `agent.id` listado.
   - Ver traces, transactions, errors, SQL, JVM.