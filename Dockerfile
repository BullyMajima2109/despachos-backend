
FROM maven:3.9.6-eclipse-temurin-17-alpine AS builder
WORKDIR /build
COPY pom.xml .
RUN mvn dependency:go-offline -B

COPY src ./src
RUN mvn clean package -DskipTests -B

FROM eclipse-temurin:17-jre-alpine AS runtime


LABEL maintainer="Innovatech Chile"
LABEL app="despachos-backend"
LABEL version="1.0"

WORKDIR /app

RUN addgroup -S appgroup && adduser -S appuser -G appgroup
COPY --from=builder /build/target/*.jar app.jar

RUN chown appuser:appgroup app.jar
USER appuser
EXPOSE 8081

ENV DB_ENDPOINT=localhost \
    DB_PORT=3306 \
    DB_NAME=despachos_db \
    DB_USERNAME=root \
    DB_PASSWORD=secret \
    JAVA_OPTS="-Xms256m -Xmx512m"
    
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
