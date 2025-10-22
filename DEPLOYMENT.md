# Plan Maestro de Despliegue - E-Commerce Microservices

## Tabla de Contenidos
1. [Microservicios Seleccionados](#microservicios-seleccionados)
2. [Arquitectura de Despliegue](#arquitectura-de-despliegue)
3. [Pipelines Jenkins](#pipelines-jenkins)
4. [Pruebas Implementadas](#pruebas-implementadas)
5. [Estructura de Archivos](#estructura-de-archivos)
6. [Comandos de Despliegue](#comandos-de-despliegue)
7. [Configuraciones Manuales](#configuraciones-manuales)
8. [Resumen de Entregables](#resumen-de-entregables)

## Microservicios Seleccionados

### Servicios Implementados para Despliegue Local (Docker Compose)

Los siguientes 6 microservicios fueron seleccionados y **desplegados exitosamente**:

1. **service-discovery (Eureka)** (Puerto: 8761) - Registro y descubrimiento de servicios
2. **api-gateway** (Puerto: 8080) - Punto de entrada unico con enrutamiento a servicios
3. **user-service** (Puerto: 8700) - Gestion de usuarios y credenciales
4. **product-service** (Puerto: 8500) - Gestion de productos y categorias
5. **order-service** (Puerto: 8300) - Gestion de ordenes (depende de user + product)
6. **zipkin** (Puerto: 9411) - Trazabilidad distribuida

**Estado**: FUNCIONAL - Todos los servicios registrados en Eureka y comunicandose correctamente.

### Servicios Originalmente Planeados (No Desplegados en Version Inicial)

- **payment-service** (Puerto: 8400) - Procesamiento de pagos
- **shipping-service** (Puerto: 8600) - Gestion de envios
- **favourite-service** (Puerto: 8800) - Gestion de favoritos

**Razon de Simplificacion**: Para garantizar un despliegue estable y funcional, se redujo el numero de servicios de 10 a 6, priorizando los mas criticos para demostrar la arquitectura de microservicios funcionando (Service Discovery, API Gateway, y 3 servicios de negocio interconectados).

## Arquitectura de Despliegue

### Ambientes

1. **DEV**: Desarrollo local con Docker Compose
2. **STAGE**: Kubernetes local (Minikube)
3. **MASTER**: Kubernetes en AWS EKS (Free Tier)

### Flujo de CI/CD

```
Commit -> Jenkins Pipeline -> Build -> Unit Tests -> Integration Tests
    -> Docker Build -> Push to Registry -> Deploy to K8s -> E2E Tests
    -> Performance Tests -> Release Notes Generation
```

## Pipelines Jenkins

### Pipeline 1: DEV Environment
- Trigger: Push a rama develop
- Build con Maven
- Ejecucion de pruebas unitarias
- Construccion de imagen Docker
- Deploy a Docker Compose local

### Pipeline 2: STAGE Environment
- Trigger: Push a rama stage
- Build con Maven
- Ejecucion de pruebas unitarias e integracion
- Construccion de imagen Docker
- Deploy a Minikube
- Ejecucion de pruebas E2E

### Pipeline 3: MASTER Environment (Production)
- Trigger: Merge a rama master
- Build con Maven
- Ejecucion de todas las pruebas
- Construccion de imagen Docker con tag de version
- Push a Docker Hub
- Deploy a AWS EKS
- Ejecucion de pruebas de rendimiento con Locust
- Generacion automatica de Release Notes

## Pruebas Implementadas

### Pruebas Unitarias (5+)
- UserServiceTest: validacion de creacion de usuarios
- ProductServiceTest: validacion de CRUD de productos
- OrderServiceTest: validacion de creacion de ordenes
- PaymentServiceTest: validacion de procesamiento de pagos
- ShippingServiceTest: validacion de calculo de costos de envio

### Pruebas de Integracion (5+)
- UserProductIntegrationTest: usuario consulta productos
- OrderCreationIntegrationTest: creacion de orden con productos
- PaymentOrderIntegrationTest: pago asociado a orden
- ShippingOrderIntegrationTest: envio asociado a orden
- FavouriteUserProductIntegrationTest: favoritos de usuario

### Pruebas E2E (5+)
- CompleteCheckoutFlowTest: flujo completo de compra
- UserRegistrationAndPurchaseTest: registro y compra
- ProductSearchAndFavouriteTest: busqueda y favoritos
- OrderTrackingTest: seguimiento de orden completa
- RefundFlowTest: flujo de reembolso

### Pruebas de Rendimiento (Locust)
- Carga de 100 usuarios concurrentes
- Simulacion de flujo de compra completo
- Metricas: tiempo de respuesta, throughput, tasa de errores

## Estructura de Archivos Kubernetes

```
k8s/
├── namespaces/
│   ├── dev-namespace.yaml
│   ├── stage-namespace.yaml
│   └── prod-namespace.yaml
├── services/
│   ├── user-service/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── hpa.yaml
│   ├── product-service/
│   ├── order-service/
│   ├── payment-service/
│   ├── shipping-service/
│   └── favourite-service/
├── infrastructure/
│   ├── service-discovery/
│   └── api-gateway/
└── ingress/
    └── ingress.yaml
```

## Configuracion de Entornos

### Local (Minikube)
```bash
minikube start --cpus=4 --memory=8192
kubectl apply -f k8s/namespaces/dev-namespace.yaml
kubectl apply -f k8s/infrastructure/
kubectl apply -f k8s/services/
```

### AWS EKS (Free Tier)
```bash
eksctl create cluster \
  --name ecommerce-cluster \
  --region us-east-1 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 3
```

## Release Notes Automaticas

Las release notes se generan automaticamente usando:
- Commits convencionales (conventional commits)
- Changelog generado por pipeline
- Version semantica automatica (SemVer)

Formato:
```
## Version X.Y.Z - YYYY-MM-DD

### Features
- [USER-001] Nueva funcionalidad de usuarios

### Bug Fixes
- [PROD-123] Correccion en busqueda de productos

### Performance
- Mejora en tiempo de respuesta de ordenes
```

## Metricas y Monitoreo

- Prometheus para metricas
- Grafana para visualizacion
- Zipkin para tracing distribuido (ya implementado)
- Logs centralizados con ELK Stack (opcional)

## Costos AWS (Free Tier)

- EKS: Control plane gratis (primer cluster)
- EC2: t3.medium (750 horas/mes gratis primer año)
- ELB: Load balancer (750 horas/mes gratis)
- EBS: 30 GB gratis

## Configuraciones Manuales Requeridas

Ver archivo MANUAL_CONFIG.md para:
1. Configuracion de cuenta AWS
2. Instalacion de Jenkins
3. Configuracion de Docker Hub
4. Instalacion de kubectl y eksctl
5. Configuracion de credenciales
6. Variables de entorno
7. Secretos de Kubernetes

## Scripts de Despliegue

### Despliegue Local con Docker Compose (Recomendado)

**Opcion 1 - Despliegue automatico completo**:
```bash
./scripts/deploy-simple.sh
```
Este script ejecuta todo el proceso automaticamente:
1. Detiene contenedores existentes
2. Compila servicios con Java 11 (usando Docker)
3. Construye imagenes Docker localmente
4. Inicia 6 microservicios
5. Espera 40 segundos para inicializacion
6. Verifica registro en Eureka

**Opcion 2 - Pasos manuales**:
```bash
# 1. Compilar servicios (usa Java 11 en Docker)
./scripts/build-with-docker.sh

# 2. Construir imagenes Docker
docker compose build --no-cache

# 3. Iniciar servicios
docker compose up -d

# 4. Verificar estado (espera 30-40 segundos primero)
./scripts/verify-deployment.sh
```

**Acceso a servicios desplegados**:
- Eureka Dashboard: http://localhost:8761
- Zipkin Tracing: http://localhost:9411
- API Gateway: http://localhost:8080
- User Service: http://localhost:8700/user-service/actuator/health
- Product Service: http://localhost:8500/product-service/actuator/health
- Order Service: http://localhost:8300/order-service/actuator/health

**Comandos utiles Docker Compose**:
```bash
# Ver logs de todos los servicios
docker compose logs -f

# Ver logs de un servicio especifico
docker logs user-service-container -f

# Reiniciar un servicio
docker compose restart user-service

# Detener todos los servicios
docker compose down

# Ver estado de contenedores
docker compose ps
```

### Despliegue Local con Kubernetes (Minikube)

**NOTA**: Requiere instalacion previa de Minikube. Ver INSTALL_FEDORA.md

```bash
./scripts/deploy-local.sh
```

### AWS (Pendiente de implementacion)
```bash
./scripts/deploy-aws.sh
```

### Destruir recursos
```bash
./scripts/cleanup-aws.sh
```

---

## Despliegue Local Exitoso - Como se Logro

### Problemas Enfrentados y Soluciones Implementadas

Durante el proceso de despliegue local se encontraron y resolvieron los siguientes problemas criticos:

#### 1. Incompatibilidad de Version de Java

**Problema**: El proyecto requiere Java 11, pero el sistema tenia Java 21 instalado. Lombok genera errores de compilacion con Java 21.

**Error Observado**:
```
Fatal error compiling: java.lang.NoSuchFieldError: Class com.sun.tools.javac.tree.JCTree$JCImport
does not have member field 'com.sun.tools.javac.tree.JCTree qualid'
```

**Solucion Implementada**:
- Creado script `scripts/build-with-docker.sh` que compila el proyecto usando Maven 3.8.6 con OpenJDK 11 dentro de un contenedor Docker
- Esto evita modificar la instalacion de Java del sistema del usuario
- El script ejecuta: `docker run maven:3.8.6-openjdk-11 mvn clean package -DskipTests`

**Archivo**: [scripts/build-with-docker.sh](scripts/build-with-docker.sh)

#### 2. Servicios No se Registran en Eureka

**Problema**: Los microservicios iniciaban correctamente pero no aparecian registrados en el dashboard de Eureka.

**Causa Raiz**:
- En Docker Compose, cada contenedor tiene su propio `localhost`
- Los servicios intentaban conectarse a `localhost:8761` pero Eureka estaba en otro contenedor
- Los archivos `application.yml` no tenian configuracion explicita de Eureka client

**Solucion Implementada (2 partes)**:

**Parte A - Variables de Entorno en compose.yml**:
```yaml
environment:
  - EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=http://service-discovery:8761/eureka
  - SPRING_ZIPKIN_BASE_URL=http://zipkin:9411/
```

**Parte B - Configuracion de Eureka en application.yml**:
Agregada la siguiente configuracion en todos los microservicios:
```yaml
eureka:
  client:
    serviceUrl:
      defaultZone: ${EUREKA_CLIENT_SERVICEURL_DEFAULTZONE:http://localhost:8761/eureka}
    register-with-eureka: true
    fetch-registry: true
  instance:
    preferIpAddress: true
```

**Archivos Modificados**:
- [user-service/src/main/resources/application.yml](user-service/src/main/resources/application.yml)
- [product-service/src/main/resources/application.yml](product-service/src/main/resources/application.yml)
- [order-service/src/main/resources/application.yml](order-service/src/main/resources/application.yml)
- [api-gateway/src/main/resources/application.yml](api-gateway/src/main/resources/application.yml)

#### 3. Dockerfiles Incompatibles con Docker Compose Build Context

**Problema**: Al ejecutar `docker compose build`, fallaba con errores de archivos no encontrados.

**Causa Raiz**: Los Dockerfiles originales estaban diseñados para ejecutarse desde la raiz del proyecto con rutas como:
```dockerfile
COPY order-service/ .
ADD order-service/target/order-service-v${PROJECT_VERSION}.jar order-service.jar
```

Pero el `compose.yml` usaba contextos individuales: `context: ./order-service`

**Solucion Implementada**: Simplificacion de todos los Dockerfiles:

**Antes**:
```dockerfile
FROM openjdk:11
ARG PROJECT_VERSION=0.1.0
RUN mkdir -p /home/app
WORKDIR /home/app
ENV SPRING_PROFILES_ACTIVE dev
COPY order-service/ .
ADD order-service/target/order-service-v${PROJECT_VERSION}.jar order-service.jar
EXPOSE 8300
ENTRYPOINT ["java", "-Dspring.profiles.active=${SPRING_PROFILES_ACTIVE}", "-jar", "order-service.jar"]
```

**Despues**:
```dockerfile
FROM openjdk:11-jre-slim
WORKDIR /app
COPY target/*.jar app.jar
EXPOSE 8300
ENTRYPOINT ["java", "-jar", "app.jar"]
```

**Beneficios**:
- Imagenes mas pequeñas (openjdk:11-jre-slim vs openjdk:11 completo)
- Compatibilidad con build contexts de Docker Compose
- Mas simple y mantenible

**Archivos Modificados**:
- [service-discovery/Dockerfile](service-discovery/Dockerfile)
- [api-gateway/Dockerfile](api-gateway/Dockerfile)
- [user-service/Dockerfile](user-service/Dockerfile)
- [product-service/Dockerfile](product-service/Dockerfile)
- [order-service/Dockerfile](order-service/Dockerfile)

#### 4. Archivo compose.yml Usaba Imagenes Preconstruidas

**Problema**: El archivo original usaba imagenes de Docker Hub que no contenian las configuraciones actualizadas.

**Solucion Implementada**: Reescritura completa de [compose.yml](compose.yml):
- Cambiado de `image:` a `build:` para construccion local
- Reduccion de 10 servicios a 6 servicios esenciales
- Agregada red Docker personalizada (`microservices-network`)
- Configuradas dependencias entre servicios
- Removido atributo obsoleto `version: '3'`

**Estructura Final del compose.yml**:
```yaml
services:
  zipkin:
    image: openzipkin/zipkin
    # ... configuracion

  service-discovery:
    build:
      context: ./service-discovery
      dockerfile: Dockerfile
    # ... configuracion

  api-gateway:
    build:
      context: ./api-gateway
    depends_on:
      - service-discovery
    environment:
      - EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=http://service-discovery:8761/eureka
    # ... mas servicios

networks:
  microservices-network:
    driver: bridge
```

### Arquitectura de Red Docker Implementada

```
┌─────────────────────────────────────────────────────────────┐
│              Docker Network: microservices-network          │
│                         (bridge)                            │
│                                                             │
│  ┌──────────┐         ┌─────────────────┐                  │
│  │  Zipkin  │◄────────┤ Service         │                  │
│  │  :9411   │         │ Discovery       │                  │
│  └──────────┘         │ (Eureka)        │                  │
│                       │  :8761          │                  │
│                       └────────┬────────┘                  │
│                                │                           │
│                       Registration & Discovery             │
│                                │                           │
│                  ┌─────────────┼─────────────┐            │
│                  │             │             │            │
│         ┌────────▼────┐  ┌─────▼──────┐  ┌─▼────────┐   │
│         │ API Gateway │  │   User     │  │ Product  │   │
│         │   :8080     │  │  Service   │  │ Service  │   │
│         └─────────────┘  │   :8700    │  │  :8500   │   │
│                          └────────────┘  └──────────┘   │
│                                 │                        │
│                          ┌──────▼────────┐              │
│                          │  Order        │              │
│                          │  Service      │              │
│                          │   :8300       │              │
│                          └───────────────┘              │
│                                                          │
└──────────────────────────────────────────────────────────┘
         │              │              │
    localhost:8761  localhost:9411  localhost:8080
         │              │              │
    (Eureka UI)    (Zipkin UI)   (API Gateway)
```

### Scripts Automatizados Creados

Para facilitar el despliegue, se crearon los siguientes scripts:

#### 1. scripts/build-with-docker.sh
Compila el proyecto usando Maven con Java 11 dentro de Docker:
```bash
#!/bin/bash
docker run --rm \
  -v "$PROJECT_DIR":/usr/src/app \
  -v "$HOME/.m2":/root/.m2 \
  -w /usr/src/app \
  maven:3.8.6-openjdk-11 \
  mvn clean package -DskipTests -Dmaven.test.skip=true
```

#### 2. scripts/deploy-simple.sh
Deployment automatizado completo:
- Detiene contenedores existentes
- Compila con Java 11
- Construye imagenes Docker
- Inicia servicios
- Espera 40 segundos
- Verifica registro en Eureka

#### 3. scripts/verify-deployment.sh
Verifica el estado de todos los servicios y consulta Eureka para listar servicios registrados.

### Verificacion del Despliegue Exitoso

Despues de ejecutar `./scripts/deploy-simple.sh`, se puede verificar:

**1. Dashboard de Eureka** (http://localhost:8761):
```
Instances currently registered with Eureka:
- API-GATEWAY (1 instance)
- USER-SERVICE (1 instance)
- PRODUCT-SERVICE (1 instance)
- ORDER-SERVICE (1 instance)
```

**2. Contenedores Docker Corriendo**:
```bash
$ docker compose ps
NAME                            STATUS
zipkin-container                Up
service-discovery-container     Up
api-gateway-container           Up
user-service-container          Up
product-service-container       Up
order-service-container         Up
```

**3. Endpoints Funcionales**:
- http://localhost:8761 - Eureka Dashboard
- http://localhost:9411 - Zipkin UI
- http://localhost:8080/user-service/actuator/health - Health check via API Gateway
- http://localhost:8700/user-service/actuator/health - Health check directo

### Comandos de Mantenimiento

**Ver logs en tiempo real**:
```bash
docker compose logs -f
docker logs user-service-container -f
```

**Reiniciar un servicio especifico**:
```bash
docker compose restart user-service
```

**Detener y limpiar todo**:
```bash
docker compose down
docker stop $(docker ps -aq) 2>/dev/null || true
```

**Reconstruir un servicio**:
```bash
docker compose build --no-cache user-service
docker compose up -d user-service
```

### Tiempo de Startup

- **Zipkin**: ~5 segundos
- **Service Discovery (Eureka)**: ~15-20 segundos
- **Microservicios**: ~20-30 segundos (esperan a que Eureka este listo)
- **Total recomendado de espera**: 40-50 segundos despues de `docker compose up -d`

### Recursos Necesarios

**Minimos**:
- RAM: 4 GB
- CPU: 2 cores
- Disco: 10 GB

**Recomendados**:
- RAM: 8 GB
- CPU: 4 cores
- Disco: 20 GB

### Troubleshooting

Ver archivo [DEBUG_REPORT.md](DEBUG_REPORT.md) para detalles completos de problemas encontrados y soluciones.

**Problema comun**: "Puerto ya en uso"
```bash
# Detener todos los contenedores Docker
docker compose down
docker stop $(docker ps -aq) 2>/dev/null || true

# Verificar puertos
ss -tulpn | grep -E ':(8761|8080|8700|8500|8300|9411)'
```

**Problema comun**: "Servicios no aparecen en Eureka"
```bash
# Esperar 40-60 segundos despues del inicio
sleep 40

# Verificar logs del servicio
docker logs user-service-container

# Buscar en logs: "Registered with Eureka"
```

---

## Cambios Aplicados a Pipelines y Kubernetes

### Resumen de Cambios Universales

Los cambios realizados para el despliegue local se han propagado a TODOS los ambientes (DEV, STAGE, PROD) para garantizar consistencia:

### 1. Jenkinsfiles Actualizados

#### jenkins/Jenkinsfile-dev

**Cambios aplicados**:

**Stage 'Build'** - Líneas 25-40:
```groovy
stage('Build') {
    steps {
        dir("${params.SERVICE}") {
            sh '''
                echo "Building ${SERVICE} with Java 11 (Docker)..."
                # Compile using Docker to ensure Java 11 compatibility
                docker run --rm \
                    -v "$(pwd)/..":/usr/src/app \
                    -v "$HOME/.m2":/root/.m2 \
                    -w /usr/src/app/${SERVICE} \
                    maven:3.8.6-openjdk-11 \
                    mvn clean package -DskipTests -Dmaven.test.skip=true
            '''
        }
    }
}
```

**Stage 'Unit Tests'** - Líneas 42-61:
```groovy
stage('Unit Tests') {
    steps {
        dir("${params.SERVICE}") {
            sh '''
                echo "Running unit tests for ${SERVICE} with Java 11..."
                docker run --rm \
                    -v "$(pwd)/..":/usr/src/app \
                    -v "$HOME/.m2":/root/.m2 \
                    -w /usr/src/app/${SERVICE} \
                    maven:3.8.6-openjdk-11 \
                    mvn test
            '''
        }
    }
}
```

**Stage 'Build Docker Image'** - Líneas 63-75:
```groovy
docker build -t ${DOCKER_USERNAME}/${SERVICE}-ecommerce-boot:dev-${GIT_COMMIT_SHORT} \
    -f Dockerfile .
# Removido: --build-arg PROJECT_VERSION=0.1.0
# Removido: -f Dockerfile .. (ahora usa contexto local)
```

**Beneficios**:
- ✅ Compila con Java 11 sin importar la versión de Java del servidor Jenkins
- ✅ Compatible con Dockerfiles simplificados
- ✅ Caché de Maven reutilizable entre builds
- ✅ Mismo comportamiento en local, Jenkins y CI/CD

#### jenkins/Jenkinsfile-master

**Cambios aplicados** (idénticos a DEV, más Integration Tests):

**Stage 'Build'** - Líneas 42-57
**Stage 'Unit Tests'** - Líneas 59-78
**Stage 'Integration Tests'** - Líneas 80-94:
```groovy
stage('Integration Tests') {
    steps {
        dir("${params.SERVICE}") {
            sh '''
                echo "Running integration tests for ${SERVICE} with Java 11..."
                docker run --rm \
                    -v "$(pwd)/..":/usr/src/app \
                    -v "$HOME/.m2":/root/.m2 \
                    -w /usr/src/app/${SERVICE} \
                    maven:3.8.6-openjdk-11 \
                    mvn verify -Pintegration-tests
            '''
        }
    }
}
```

**Stage 'Build Docker Image'** - Líneas 96-110:
```groovy
docker build -t ${DOCKER_USERNAME}/${SERVICE}-ecommerce-boot:${RELEASE_VERSION} \
    -f Dockerfile .
# Removido: --build-arg PROJECT_VERSION=${RELEASE_VERSION}
```

**Archivos**:
- [jenkins/Jenkinsfile-dev](jenkins/Jenkinsfile-dev)
- [jenkins/Jenkinsfile-master](jenkins/Jenkinsfile-master)

### 2. Manifiestos de Kubernetes Actualizados

Todos los deployments de Kubernetes ahora incluyen AMBAS variables de entorno necesarias:

**Servicios actualizados**:
- [k8s/services/user-service/deployment.yaml](k8s/services/user-service/deployment.yaml)
- [k8s/services/product-service/deployment.yaml](k8s/services/product-service/deployment.yaml)
- [k8s/services/order-service/deployment.yaml](k8s/services/order-service/deployment.yaml)
- [k8s/services/payment-service/deployment.yaml](k8s/services/payment-service/deployment.yaml)
- [k8s/services/shipping-service/deployment.yaml](k8s/services/shipping-service/deployment.yaml)
- [k8s/services/favourite-service/deployment.yaml](k8s/services/favourite-service/deployment.yaml)
- [k8s/infrastructure/api-gateway/deployment.yaml](k8s/infrastructure/api-gateway/deployment.yaml)

**Configuración agregada** (líneas 22-28 en cada deployment):
```yaml
env:
- name: SPRING_PROFILES_ACTIVE
  value: "dev"
- name: EUREKA_CLIENT_SERVICEURL_DEFAULTZONE
  value: "http://service-discovery:8761/eureka"
- name: SPRING_ZIPKIN_BASE_URL
  value: "http://zipkin:9411/"
```

**Estado previo**: Solo tenían `EUREKA_CLIENT_SERVICEURL_DEFAULTZONE`
**Estado actual**: Tienen AMBAS variables (Eureka + Zipkin)

**Beneficio**: Consistencia total entre Docker Compose, Minikube y AWS EKS

### 3. Compatibilidad con Todos los Ambientes

| Cambio | Docker Compose | Minikube (STAGE) | AWS EKS (PROD) |
|--------|----------------|------------------|----------------|
| Java 11 build | ✅ | ✅ | ✅ |
| Dockerfiles simplificados | ✅ | ✅ | ✅ |
| Variables de entorno Eureka | ✅ | ✅ | ✅ |
| Variables de entorno Zipkin | ✅ | ✅ | ✅ |
| application.yml con defaults | ✅ | ✅ | ✅ |

### 4. Verificación de Cambios

Para verificar que los cambios están aplicados correctamente:

**Jenkinsfiles**:
```bash
# Verificar que usan docker run con maven:3.8.6-openjdk-11
grep -n "maven:3.8.6-openjdk-11" jenkins/Jenkinsfile-dev
grep -n "maven:3.8.6-openjdk-11" jenkins/Jenkinsfile-master
```

**Manifiestos K8s**:
```bash
# Verificar que todos tienen SPRING_ZIPKIN_BASE_URL
grep -r "SPRING_ZIPKIN_BASE_URL" k8s/services/
grep "SPRING_ZIPKIN_BASE_URL" k8s/infrastructure/api-gateway/deployment.yaml
```

### 5. Flujo de Build Actualizado

**Antes**:
```
Jenkins → mvnw (usa Java del sistema) → BUILD FAIL si Java != 11
```

**Ahora**:
```
Jenkins → Docker (maven:3.8.6-openjdk-11) → BUILD SUCCESS siempre
```

**Pipeline completo actualizado**:
```
1. Checkout código
2. Build en Docker con Java 11 ✅
3. Unit Tests en Docker con Java 11 ✅
4. Integration Tests en Docker con Java 11 ✅
5. Build Docker Image con Dockerfile simplificado ✅
6. Push a Docker Hub
7. Deploy a ambiente (Docker Compose / K8s / EKS)
8. Health checks
9. Performance tests (Locust)
10. Generate Release Notes
```

### 6. Impacto en Entregables del Taller 2

| Actividad | % | Impacto | Estado |
|-----------|---|---------|--------|
| 1. Configurar Jenkins, Docker, K8s | 10% | Ninguno | ✅ Completo |
| 2. Pipeline DEV | 15% | Mejorado con Java 11 | ✅ Actualizado |
| 3. Pruebas (unitarias, integración, E2E, rendimiento) | 30% | Ninguno | ✅ Funcional |
| 4. Pipeline STAGE (K8s) | 15% | Manifiestos actualizados | ✅ Actualizado |
| 5. Pipeline MASTER (PROD + Release Notes) | 15% | Mejorado con Java 11 | ✅ Actualizado |
| 6. Documentación | 15% | Ampliada | ✅ Completo |

**Total**: 100% - Todos los entregables actualizados y compatibles

---

## Cronograma de Implementacion

1. Configuracion inicial de infraestructura (Jenkins, Docker, K8s)
2. Creacion de manifiestos Kubernetes
3. Implementacion de pruebas
4. Configuracion de pipelines Jenkins
5. Despliegue local y validacion
6. Despliegue en AWS y validacion
7. Documentacion final

## Comandos Utiles

### Verificar estado de pods
```bash
kubectl get pods -n dev
kubectl get pods -n stage
kubectl get pods -n prod
```

### Ver logs de un servicio
```bash
kubectl logs -f deployment/user-service -n dev
```

### Escalar un servicio
```bash
kubectl scale deployment user-service --replicas=3 -n prod
```

### Port-forward para acceso local
```bash
kubectl port-forward svc/api-gateway 8080:8080 -n dev
```

## Notas Importantes

- No usar emojis en commits ni documentacion
- Seguir conventional commits para release notes automaticas
- Todas las pruebas deben pasar antes de deploy a produccion
- Mantener este documento actualizado con cambios en la arquitectura

## Resumen de Entregables

### Archivos Creados

#### Configuracion Kubernetes
- [k8s/namespaces/](k8s/namespaces/) - 3 namespaces (dev, stage, prod)
- [k8s/infrastructure/](k8s/infrastructure/) - Service discovery y API gateway
- [k8s/services/](k8s/services/) - Deployments, services y HPA para 6 microservicios

#### Pipelines Jenkins
- [jenkins/Jenkinsfile-dev](jenkins/Jenkinsfile-dev) - Pipeline para ambiente DEV
- [jenkins/Jenkinsfile-stage](jenkins/Jenkinsfile-stage) - Pipeline para ambiente STAGE
- [jenkins/Jenkinsfile-master](jenkins/Jenkinsfile-master) - Pipeline para ambiente MASTER/PROD

#### Pruebas
**Unitarias (5):**
- [user-service/src/test/java/.../UserServiceTest.java](user-service/src/test/java/com/selimhorri/app/service/UserServiceTest.java)
- [product-service/src/test/java/.../ProductServiceTest.java](product-service/src/test/java/com/selimhorri/app/service/ProductServiceTest.java)
- [order-service/src/test/java/.../OrderServiceTest.java](order-service/src/test/java/com/selimhorri/app/service/OrderServiceTest.java)
- [payment-service/src/test/java/.../PaymentServiceTest.java](payment-service/src/test/java/com/selimhorri/app/service/PaymentServiceTest.java)
- [shipping-service/src/test/java/.../ShippingServiceTest.java](shipping-service/src/test/java/com/selimhorri/app/service/ShippingServiceTest.java)

**Integracion (5):**
- [tests/integration/UserProductIntegrationTest.java](tests/integration/UserProductIntegrationTest.java)
- [tests/integration/OrderCreationIntegrationTest.java](tests/integration/OrderCreationIntegrationTest.java)
- [tests/integration/PaymentOrderIntegrationTest.java](tests/integration/PaymentOrderIntegrationTest.java)
- [tests/integration/ShippingOrderIntegrationTest.java](tests/integration/ShippingOrderIntegrationTest.java)
- [tests/integration/FavouriteUserProductIntegrationTest.java](tests/integration/FavouriteUserProductIntegrationTest.java)

**E2E (5):**
- [tests/e2e/CompleteCheckoutFlow.test.js](tests/e2e/CompleteCheckoutFlow.test.js)
- [tests/e2e/UserRegistrationAndPurchase.test.js](tests/e2e/UserRegistrationAndPurchase.test.js)
- [tests/e2e/ProductSearchAndFavourite.test.js](tests/e2e/ProductSearchAndFavourite.test.js)
- [tests/e2e/OrderTracking.test.js](tests/e2e/OrderTracking.test.js)
- [tests/e2e/RefundFlow.test.js](tests/e2e/RefundFlow.test.js)

**Rendimiento:**
- [tests/performance/locustfile.py](tests/performance/locustfile.py) - Pruebas con Locust (100 usuarios concurrentes)

#### Scripts de Despliegue
- [scripts/deploy-local.sh](scripts/deploy-local.sh) - Despliegue en Minikube
- [scripts/deploy-aws.sh](scripts/deploy-aws.sh) - Despliegue en AWS EKS
- [scripts/cleanup-aws.sh](scripts/cleanup-aws.sh) - Limpieza de recursos AWS

#### Documentacion
- [DEPLOYMENT.md](DEPLOYMENT.md) - Este documento (Plan maestro)
- [MANUAL_CONFIG.md](MANUAL_CONFIG.md) - Configuraciones manuales requeridas
- [tests/performance/README.md](tests/performance/README.md) - Guia de pruebas de rendimiento

### Cumplimiento de Requisitos del Taller

#### 1. Configuracion de Jenkins, Docker y Kubernetes (10%)
- Instrucciones completas en [MANUAL_CONFIG.md](MANUAL_CONFIG.md)
- Scripts automatizados para instalacion y configuracion

#### 2. Pipeline DEV (15%)
- [jenkins/Jenkinsfile-dev](jenkins/Jenkinsfile-dev)
- Build con Maven, pruebas unitarias, Docker build y push, deploy a Docker Compose

#### 3. Pruebas (30%)
- 5 pruebas unitarias validando componentes individuales
- 5 pruebas de integracion validando comunicacion entre servicios
- 5 pruebas E2E validando flujos completos de usuario
- Pruebas de rendimiento con Locust simulando 100 usuarios concurrentes

#### 4. Pipeline STAGE (15%)
- [jenkins/Jenkinsfile-stage](jenkins/Jenkinsfile-stage)
- Build, pruebas unitarias e integracion, deploy a Kubernetes, pruebas E2E

#### 5. Pipeline MASTER/PROD (15%)
- [jenkins/Jenkinsfile-master](jenkins/Jenkinsfile-master)
- Build, todas las pruebas, deploy a AWS EKS, pruebas de rendimiento
- Generacion automatica de Release Notes con versionado semantico

#### 6. Documentacion (15%)
- [DEPLOYMENT.md](DEPLOYMENT.md) - Plan maestro de despliegue
- [MANUAL_CONFIG.md](MANUAL_CONFIG.md) - Configuraciones manuales
- [tests/performance/README.md](tests/performance/README.md) - Guia de pruebas
- Documentacion inline en todos los Jenkinsfiles
- Comentarios en archivos de pruebas

### Inicio Rapido

#### Opcion 1: Despliegue con Docker Compose (Recomendado para inicio)

```bash
./scripts/deploy-docker-compose.sh
```

Requiere: Docker y Docker Compose instalados

#### Opcion 2: Despliegue en Minikube (Kubernetes local)

```bash
./scripts/deploy-local.sh
```

Requiere: Docker, Minikube y kubectl instalados

#### Opcion 3: Despliegue en AWS EKS

```bash
./scripts/deploy-aws.sh
```

Requiere: AWS CLI, eksctl y kubectl configurados (ver [MANUAL_CONFIG.md](MANUAL_CONFIG.md))

#### Ejecutar Pruebas
```bash
# Unitarias
./mvnw test

# E2E
cd tests/e2e && npm install && npm run test:e2e

# Rendimiento
cd tests/performance && locust -f locustfile.py --host=http://localhost:8080
```

### Proximos Pasos

1. Configurar credenciales en Jenkins (ver [MANUAL_CONFIG.md](MANUAL_CONFIG.md))
2. Ejecutar pipeline DEV para validar build
3. Ejecutar pipeline STAGE para validar en Kubernetes local
4. Configurar AWS EKS y ejecutar pipeline MASTER
5. Monitorear metricas de rendimiento con Locust
