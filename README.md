# 🚀 Backend Despachos - Springboot API REST

API REST desarrollada con **Spring Boot 3.4.4** y **Java 17** para la gestión de despachos de Innovatech Chile.  
Desplegada en contenedores Docker sobre **AWS EC2**, con pipeline CI/CD automatizado vía **GitHub Actions** y registro de imágenes en **AWS ECR**.

---

## 📋 Tabla de Contenidos

- [Tecnologías](#tecnologías)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Configuración Local](#configuración-local)
- [Docker](#docker)
- [Pipeline CI/CD](#pipeline-cicd)
- [Variables de Entorno](#variables-de-entorno)
- [Endpoints de la API](#endpoints-de-la-api)

---

## 🛠 Tecnologías

| Tecnología | Versión | Uso |
|---|---|---|
| Java | 17 | Lenguaje base |
| Spring Boot | 3.4.4 | Framework API REST |
| MySQL | 8.0 | Base de datos |
| Docker | latest | Contenedorización |
| GitHub Actions | - | Pipeline CI/CD |
| AWS ECR | - | Registro de imágenes |
| AWS EC2 | - | Despliegue en nube |

---

## 📁 Estructura del Proyecto

```
Springboot-API-REST-DESPACHO/
├── src/
│   └── main/
│       ├── java/com/citt/
│       │   ├── config/
│       │   │   ├── CorsConfig.java       # Configuración CORS
│       │   │   └── OpenApiConfig.java    # Swagger/OpenAPI
│       │   ├── controller/
│       │   │   └── DespachoController.java
│       │   ├── persistence/
│       │   │   ├── entity/Despacho.java
│       │   │   ├── repository/DespachoRepository.java
│       │   │   └── services/
│       │   └── SpringbootApiRestDespachoApplication.java
│       └── resources/
│           └── application.properties
├── .github/
│   └── workflows/
│       └── deploy-backend.yml   # Pipeline CI/CD
├── Dockerfile                   # Multi-stage build
├── docker-compose.yml           # Stack completo (API + MySQL)
├── .env.example                 # Plantilla de variables de entorno
└── README.md
```

---

## ⚙️ Configuración Local

### Pre-requisitos
- Docker Desktop instalado
- Git

### Pasos

```bash
# 1. Clonar el repositorio
git clone <url-del-repositorio>
cd Springboot-API-REST-DESPACHO

# 2. Crear archivo de variables de entorno
cp .env.example .env
# Editar .env con tus valores reales

# 3. Levantar el stack completo (API + MySQL)
docker compose up -d

# 4. Verificar que los contenedores estén corriendo
docker compose ps

# 5. Ver logs
docker compose logs -f backend
```

La API estará disponible en: `http://localhost:8081`  
Swagger UI: `http://localhost:8081/swagger-ui.html`

---

## 🐳 Docker

### Dockerfile (Multi-stage Build)

El Dockerfile usa **dos etapas** para optimizar el tamaño de la imagen final:

| Etapa | Imagen base | Propósito |
|---|---|---|
| `builder` | `maven:3.9.6-eclipse-temurin-17-alpine` | Compilar el proyecto |
| `runtime` | `eclipse-temurin:17-jre-alpine` | Ejecutar el JAR |

**Buenas prácticas aplicadas:**
- ✅ Multi-stage build (reduce imagen de ~600MB a ~200MB)
- ✅ Usuario no root (`appuser`) por seguridad
- ✅ Limpieza de capas intermedias
- ✅ Variables de entorno externalizadas
- ✅ Healthcheck en MySQL

### Comandos útiles

```bash
# Construir imagen manualmente
docker build -t despachos-backend:local .

# Correr solo el contenedor (requiere MySQL externo)
docker run -p 8081:8081 \
  -e DB_ENDPOINT=<host_mysql> \
  -e DB_PORT=3306 \
  -e DB_NAME=despachos_db \
  -e DB_USERNAME=appuser \
  -e DB_PASSWORD=tupassword \
  despachos-backend:local

# Detener y eliminar el stack
docker compose down

# Detener y eliminar stack + volúmenes (¡elimina datos!)
docker compose down -v
```

### Persistencia de Datos

Se usa un **Named Volume** (`despachos_mysql_data`) para la base de datos MySQL.

**¿Por qué Named Volume y no Bind Mount?**

| Criterio | Named Volume ✅ | Bind Mount |
|---|---|---|
| Portabilidad | Alta (Docker gestiona la ruta) | Baja (depende del path del host) |
| Rendimiento | Mejor en Linux | Variable |
| Gestión de permisos | Automática | Manual |
| Uso en producción | Recomendado | Para desarrollo local |

---

## 🔄 Pipeline CI/CD

El pipeline se activa automáticamente al hacer **push a la rama `deploy`**.

### Flujo

```
push a rama deploy
        │
        ▼
┌─────────────────┐
│  1. Checkout    │  Descarga el código fuente
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  2. AWS Auth    │  Configura credenciales con GitHub Secrets
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  3. ECR Login   │  Autentica Docker con el registry privado
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  4. Build+Push  │  Construye imagen y la sube a ECR (tag: sha + latest)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  5. Deploy EC2  │  SSH → pull imagen → restart contenedor
└─────────────────┘
```

### Secrets requeridos en GitHub

Ir a: `Repositorio → Settings → Secrets and variables → Actions → New repository secret`

| Secret | Descripción | Ejemplo |
|---|---|---|
| `AWS_ACCESS_KEY_ID` | Clave de acceso AWS | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | Clave secreta AWS | `wJalrXUtnFEMI/...` |
| `AWS_SESSION_TOKEN` | Token de sesión (AWS Academy) | `FwoGZXIvYXdz...` |
| `AWS_REGION` | Región AWS | `us-east-1` |
| `ECR_REGISTRY` | URL del registry ECR | `123456789.dkr.ecr.us-east-1.amazonaws.com` |
| `ECR_REPOSITORY_BACKEND` | Nombre del repositorio ECR | `despachos-backend` |
| `EC2_BACKEND_HOST` | IP pública EC2 backend | `54.123.45.67` |
| `EC2_SSH_KEY` | Contenido del archivo .pem | `-----BEGIN RSA...` |
| `EC2_USER` | Usuario SSH de EC2 | `ec2-user` |
| `DB_ENDPOINT` | Host de la base de datos | `mysql` o IP RDS |
| `DB_PORT` | Puerto MySQL | `3306` |
| `DB_NAME` | Nombre de la BD | `despachos_db` |
| `DB_USERNAME` | Usuario BD | `appuser` |
| `DB_PASSWORD` | Contraseña BD | `*****` |

---

## 🔐 Variables de Entorno

El proyecto usa variables de entorno para separar configuración del código.  
En local se definen en `.env`. En EC2 se pasan vía `docker run -e` o GitHub Secrets.

| Variable | Descripción | Default |
|---|---|---|
| `DB_ENDPOINT` | Host de MySQL | `localhost` |
| `DB_PORT` | Puerto MySQL | `3306` |
| `DB_NAME` | Nombre base de datos | `despachos_db` |
| `DB_USERNAME` | Usuario MySQL | `root` |
| `DB_PASSWORD` | Contraseña MySQL | - |
| `JAVA_OPTS` | Opciones JVM | `-Xms256m -Xmx512m` |

---

## 📡 Endpoints de la API

Base URL: `http://<ip-ec2-backend>:8081`

| Método | Endpoint | Descripción |
|---|---|---|
| `GET` | `/api/v1/despachos` | Obtener todos los despachos |
| `GET` | `/api/v1/despachos/{id}` | Obtener despacho por ID |
| `POST` | `/api/v1/despachos` | Crear nuevo despacho |
| `PUT` | `/api/v1/despachos/{id}` | Actualizar despacho |
| `DELETE` | `/api/v1/despachos/{id}` | Eliminar despacho |
| `GET` | `/swagger-ui.html` | Documentación interactiva |

---

## 📝 Historial de Commits

El repositorio sigue la convención de commits:
- `feat:` nueva funcionalidad
- `fix:` corrección de error
- `docker:` cambios en configuración Docker
- `ci:` cambios en pipeline CI/CD
- `docs:` cambios en documentación
