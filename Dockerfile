# ============================================================
# STAGE 1: BUILD
# Compilamos el proyecto con Maven usando JDK 17
# Usamos una imagen oficial slim para reducir tamaño
# ============================================================
FROM maven:3.9.6-eclipse-temurin-17-alpine AS builder

# Directorio de trabajo para la compilación
WORKDIR /build

# Copiamos primero solo el pom.xml para aprovechar la cache de capas
# Si el pom no cambia, Docker reutiliza la capa de dependencias
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Ahora copiamos el código fuente y compilamos
COPY src ./src
RUN mvn clean package -DskipTests -B

# ============================================================
# STAGE 2: RUNTIME
# Solo copiamos el .jar compilado a una imagen JRE mínima
# Esto reduce el tamaño final significativamente (~200MB vs ~600MB)
# ============================================================
FROM eclipse-temurin:17-jre-alpine AS runtime

# Metadatos de la imagen
LABEL maintainer="Innovatech Chile"
LABEL app="despachos-backend"
LABEL version="1.0"

# Directorio de trabajo para la app
WORKDIR /app

# ---- SEGURIDAD: usuario no root ----
# Creamos un grupo y usuario sin privilegios para ejecutar la app
# Nunca se debe correr una app en producción como root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copiamos el JAR desde la etapa de build
COPY --from=builder /build/target/*.jar app.jar

# Asignamos el JAR al usuario sin privilegios
RUN chown appuser:appgroup app.jar

# Cambiamos al usuario sin privilegios
USER appuser

# Puerto que expone el backend (definido en application.properties)
EXPOSE 8081

# Variables de entorno con valores por defecto (se sobreescriben en docker-compose o EC2)
ENV DB_ENDPOINT=localhost \
    DB_PORT=3306 \
    DB_NAME=despachos_db \
    DB_USERNAME=root \
    DB_PASSWORD=secret \
    JAVA_OPTS="-Xms256m -Xmx512m"

# Comando de arranque con opciones de memoria configurables
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
