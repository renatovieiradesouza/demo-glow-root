FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /workspace

COPY pom.xml .
RUN mvn -q -DskipTests dependency:go-offline

COPY src ./src
RUN mvn -q -DskipTests package


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


