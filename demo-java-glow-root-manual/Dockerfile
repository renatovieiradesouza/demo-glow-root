FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /workspace

# Copia o pom e o zip do Glowroot, e extrai o conteúdo na pasta do projeto (criando /workspace/glowroot)
COPY pom.xml .
COPY glowroot-0.14.4-dist.zip /tmp/glowroot.zip
RUN mkdir -p /workspace/glowroot \
    && apt-get update \
    && apt-get install -y unzip \
    && unzip /tmp/glowroot.zip -d . \
    && rm -f /tmp/glowroot.zip

COPY src ./src
RUN mvn -q -DskipTests package

FROM eclipse-temurin:21-jre AS runtime
WORKDIR /app

RUN apt-get update \
    && apt-get install -y unzip \
    && rm -rf /var/lib/apt/lists/*

# Copia o pacote Glowroot já baixado para dentro da imagem
COPY glowroot-0.14.4-dist.zip /tmp/glowroot.zip

# Instala o Glowroot Agent (runtime) a partir do ZIP local
RUN mkdir -p /glowroot \
    && unzip /tmp/glowroot.zip -d /tmp \
    && mv /tmp/glowroot/* /glowroot/ \
    && rm -rf /tmp/glowroot /tmp/glowroot.zip

# Configuração personalizada do Agent (agent.id e collector.address)
COPY glowroot/glowroot.properties /glowroot/glowroot.properties

COPY --from=build /workspace/target/demo-java-glowroot-manual-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8081

ENTRYPOINT ["java", "-javaagent:/glowroot/glowroot.jar", "-jar", "/app/app.jar"]




