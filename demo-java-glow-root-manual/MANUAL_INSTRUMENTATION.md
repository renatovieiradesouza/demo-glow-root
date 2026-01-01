# INSTRUMENTAÇÃO MANUAL COM GLOWROOT – PROJETO `demo-java-glowroot-manual`

Este projeto mostra **como escrever código de negócio já “falando a língua” do Glowroot**, usando
`org.glowroot.agent.api.Instrumentation` para criar traces e timers com contexto de negócio.

Ele complementa o projeto principal (auto‑instrumentado) e envia dados para o **mesmo Glowroot Central**,
mas com spans nomeados como `orders-create`, `orders-pay`, etc.

---

## 1. Onde está a instrumentação manual

- Projeto: `demo-java-glow-root-manual/`
- Arquivos principais:
  - `pom.xml` – depende de `glowroot.jar` via `systemPath` para compilar as anotações.
  - `src/main/java/com/renato/glowrootmanual/order/OrderService.java` – onde estão as anotações.
  - `src/main/java/com/renato/glowrootmanual/order/OrderController.java` – expõe os endpoints HTTP.
  - `glowroot/glowroot.properties` – configura `agent.id=demo-java-backend-manual` e `collector.address`.

O projeto sobe na porta **8081** e fala com o Postgres dedicado `postgres-manual`.

---

## 2. Dependência da API de instrumentação (no `pom.xml`)

Em vez de baixar uma API separada, usamos o próprio `glowroot.jar` (do ZIP `glowroot-0.14.4-dist.zip`)
como **API de compilação** via `systemPath`:

```startLine:endLine:demo-java-glow-root-manual/pom.xml
    <dependencies>
        <!-- Usamos o próprio glowroot.jar (do zip) como API de compilação.
             Ele será extraído para a pasta 'glowroot' pelo Dockerfile de build. -->
        <dependency>
            <groupId>org.glowroot</groupId>
            <artifactId>glowroot-agent</artifactId>
            <version>0.14.4</version>
            <scope>system</scope>
            <systemPath>${project.basedir}/glowroot/glowroot.jar</systemPath>
        </dependency>
        ...
```

No estágio de **build** do `Dockerfile`, o ZIP é extraído para `/workspace/glowroot`, garantindo que
`${project.basedir}/glowroot/glowroot.jar` exista quando o Maven compilar.

---

## 3. Como instrumentar um request HTTP no código

Boa prática: **não anotar o controller diretamente**, e sim o método de serviço que representa a
operação de negócio. No projeto manual isso está em `OrderService`:

```startLine:endLine:demo-java-glow-root-manual/src/main/java/com/renato/glowrootmanual/order/OrderService.java
import java.math.BigDecimal;
import java.util.Random;

import org.glowroot.agent.api.Instrumentation;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class OrderService {
    ...
    @Instrumentation.TraceEntry(
            message = "create order for customer={{0}} amount={{1}}",
            timer = "orders-create")
    @Transactional
    public Order createOrder(String customer, BigDecimal amount) { ... }
    ...
}
```

### O que essa anotação faz

- **`@Instrumentation.TraceEntry`** cria uma entrada de trace explícita:
  - `message` aparece na UI do Glowroot, com placeholders `{{0}}`, `{{1}}` substituídos pelos parâmetros.
  - `timer` cria um “bucket” de tempo (`orders-create`) que você vê no breakdown da transação.
- Como o método é chamado pelo controller de `POST /orders`, o trace final fica algo como:
  - HTTP `/orders` (auto‑instrumentação do Agent)
  - → `OrderService.createOrder` (sua instrumentação manual)
  - → `OrderService.simulateExternalCall("fraud-check")` (outro span manual)
  - → JDBC/Hibernate (auto‑instrumentado)

Da mesma forma, instrumentamos os outros casos de uso:

```startLine:endLine:demo-java-glow-root-manual/src/main/java/com/renato/glowrootmanual/order/OrderService.java
    @Instrumentation.TraceEntry(
            message = "pay order id={{0}}",
            timer = "orders-pay")
    @Transactional
    public Order payOrder(Long id) { ... }

    @Instrumentation.TraceEntry(
            message = "get order id={{0}}",
            timer = "orders-get")
    @Transactional(readOnly = true)
    public Order getOrder(Long id) { ... }

    @Instrumentation.TraceEntry(
            message = "simulate external call: {{0}}",
            timer = "external-call")
    private void simulateExternalCall(String system) { ... }
```

Assim você consegue:

- Ver claramente **quem** chamou o quê (`create order`, `pay order`, etc.).
- Medir separadamente:
  - latência da operação de negócio (`orders-create`, `orders-pay`, `orders-get`);
  - latência de “chamadas externas” simuladas (`external-call`).

---

## 4. Endpoints HTTP de teste (porta 8081)

Todos os endpoints abaixo batem no `OrderController` e disparam as anotações do `OrderService`.

- **Criar pedido**  
  Gera trace `orders-create` + span `external-call` (“fraud-check”).

```bash
curl -X POST http://localhost:8081/orders \
  -H "Content-Type: application/json" \
  -d '{"customer": "alice", "amount": 123.45}'
```

Resposta: JSON do `Order` criado, com `id`, `customer`, `amount`, `status`, `createdAt` etc.

- **Pagar pedido**  
  Gera trace `orders-pay` + `external-call` (“payment-gateway”), com falha aleatória (~20%) para gerar erros.

```bash
curl -X POST http://localhost:8081/orders/1/pay
```

- **Buscar pedido**  
  Gera trace `orders-get`.

```bash
curl http://localhost:8081/orders/1
```

Rode esses comandos algumas vezes para popular o Glowroot com sucesso e erro.

---

## 5. Onde ver a instrumentação manual no Glowroot

1. Garanta que o Glowroot Central está rodando (stack `glowroot-center`, porta `4000`).
2. Abra `http://localhost:4000` no navegador.
3. No seletor de agente, escolha **`demo-java-backend-manual`** (definido em `glowroot.properties`).

Agora:

- Em **Transactions → Web**:
  - Você verá os endpoints `/orders`, `/orders/{id}/pay`, `/orders/{id}`.
  - No detalhe de cada transação, verá os timers `orders-create`, `orders-pay`, `orders-get`.

- Em **Traces**:
  - Abra um trace de `POST /orders` ou `POST /orders/{id}/pay`.
  - A árvore deve mostrar:
    - `OrderService.createOrder` / `OrderService.payOrder`
    - `OrderService.simulateExternalCall("fraud-check" / "payment-gateway")`
    - as chamadas JDBC geradas pelo JPA/Hibernate.

- Em **Errors**:
  - As falhas aleatórias de pagamento (lançadas em `payOrder`) aparecem com:
    - mensagem “Pagamento recusado pelo gateway externo”,
    - stacktrace completo,
    - endpoint afetado.

---

## 6. Padrão para aplicar em outros serviços

Para replicar esse estilo de instrumentação manual em qualquer outro serviço Java:

1. **Tenha o Agent ligado** (auto‑instrumentação já funcionando via `-javaagent`).
2. **Escolha os pontos de negócio importantes** (ex.: criar pedido, fechar carrinho, enviar e‑mail).
3. **Anote o método de serviço**, não o controller:

```java
import org.glowroot.agent.api.Instrumentation;

@Instrumentation.TraceEntry(
    message = "approve order {{0.id}}",
    timer = "orders-approve")
public void approveOrder(Order order) {
    ...
}
```

4. (Opcional) Crie spans internos para integrações externas:

```java
@Instrumentation.TraceEntry(
    message = "call payment provider: {{0}}",
    timer = "payment-gateway")
private void callPaymentProvider(String provider) { ... }
```

Com isso, você combina:

- **auto‑instrumentação** (HTTP, JDBC, JVM),
- **instrumentação manual** nos pontos de negócio e integrações críticas,

e ganha uma visão de APM que conversa a linguagem do time de produto e de engenharia. 

