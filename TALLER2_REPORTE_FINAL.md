# 📊 Taller 2 - Reporte Final

## 🎯 Objetivos Completados

### ✅ 1. Infraestructura CI/CD en Minikube

**Jenkins**

- ✅ Desplegado en namespace `cicd` via Helm
- ✅ Accesible en: `http://192.168.49.2:30800`
- ✅ Configuración:
  - 2Gi RAM, 1 CPU (request)
  - 4Gi RAM, 2 CPU (limit)
  - PersistentVolume de 10Gi
  - Plugins: Kubernetes, Git, SonarQube Scanner, Workflow
- ✅ Credenciales:
  - Usuario: `admin`
  - Password: Ver con `kubectl exec --namespace cicd -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password`

**SonarQube**

- ✅ Desplegado en namespace `cicd` via Helm
- ✅ Community Edition 25.9
- ✅ Accesible en: `http://192.168.49.2:30900`
- ✅ Base de datos: PostgreSQL dedicada
- ✅ PersistentVolume de 10Gi
- ✅ Credenciales iniciales: `admin/admin` (cambiar en primer login)

**RBAC Kubernetes**

- ✅ ServiceAccount `jenkins` en namespace `cicd`
- ✅ ClusterRole con permisos para:
  - Deployments (get, list, create, update, patch, delete)
  - Deployments/scale (get, update, patch)
  - Pods (get, list, watch, create, delete)
  - Services (get, list, watch, create, update, patch)
- ✅ RoleBinding para desplegar en namespace `ecommerce`

---

### ✅ 2. Pipeline CI/CD Completo (Jenkinsfile)

**Características del Pipeline:**

- ✅ Pipeline declarativo con Kubernetes Agents dinámicos
- ✅ Pods multi-contenedor:
  - Maven (3.9-eclipse-temurin-17): Build y tests
  - Docker: Construcción de imágenes
  - Kubectl (alpine/k8s:1.28.3): Despliegue

**Modos de Operación:**

#### Modo Individual (Servicio Específico)

```groovy
SERVICE_NAME: user-service, product-service, order-service, api-gateway, service-discovery
RUN_SONAR: true/false
DEPLOY_TO_MINIKUBE: true/false
```

**Stages:**

1. **Checkout** - Clona repositorio
2. **Build & Test** - Maven clean package
3. **Unit Tests** - Maven test + JUnit reports
4. **SonarQube Analysis** - Análisis de calidad con Jacoco coverage
5. **Quality Gate** - Espera resultado (timeout 2 minutos)
6. **Build Docker Image** - Construye y etiqueta imagen (`:latest`, `:local`, `:BUILD_NUMBER`)
7. **Deploy to Minikube** - Escala deployment (0→1)
8. **Verify Deployment** - Espera readiness probe

#### Modo BUILD ALL (Todos los Servicios)

```groovy
SERVICE_NAME: ALL
RUN_SONAR: false (deshabilitado en modo ALL)
DEPLOY_TO_MINIKUBE: true/false
```

**Stages:**

1. **Checkout** - Clona repositorio
2. **Build All Services** - Maven build de 5 servicios en **paralelo**
3. **Build All Docker Images** - Construcción de 5 imágenes en **paralelo**
4. **Deploy to Minikube** - Despliegue **secuencial** respetando dependencias:
   - Primero: `service-discovery` (Eureka)
   - Espera a que Eureka esté READY + 30s
   - Luego: `api-gateway`, `user-service`, `product-service`, `order-service`
5. **Verify Deployment** - Verifica todos los servicios

**Optimizaciones:**

- ✅ Construcción paralela de Maven y Docker (BUILD ALL)
- ✅ Despliegue secuencial respetando dependencia de Eureka
- ✅ Timeout en Quality Gate para evitar bloqueos
- ✅ Cleanup en contenedor Maven para evitar problemas de permisos
- ✅ Try-catch para manejo de errores sin fallar pipeline

---

### ✅ 3. Microservicios Desplegados en Minikube

**Namespace: `ecommerce`**

| Servicio | Puerto | Estado | Imagen | Registro Eureka |
|----------|--------|--------|--------|-----------------|
| service-discovery | 8761 (NodePort: 30761) | ✅ Running | service-discovery:local | N/A (es Eureka) |
| api-gateway | 8080 | ✅ Running | api-gateway:local | ✅ Registrado |
| user-service | 8700 | ✅ Running | user-service:local | ✅ Registrado |
| product-service | 8500 | ✅ Running | product-service:local | ✅ Registrado |
| order-service | 8300 | ✅ Running | order-service:local | ✅ Registrado |
| zipkin | 9411 | ✅ Running | openzipkin/zipkin | N/A |

**Configuración de Recursos (por servicio):**

```yaml
requests:
  memory: 768Mi
  cpu: 100m
limits:
  memory: 2Gi
  cpu: 300m
```

**Health Checks:**

```yaml
readinessProbe:
  httpGet:
    path: /{service}/actuator/health
    port: {PORT}
  initialDelaySeconds: 120
  periodSeconds: 10
  failureThreshold: 60
  timeoutSeconds: 5
```

**Variables de Entorno:**

- `SPRING_PROFILES_ACTIVE=dev`
- `EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=http://service-discovery:8761/eureka`
- `SPRING_ZIPKIN_BASE_URL=http://zipkin:9411/`
- `JAVA_TOOL_OPTIONS=-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0`
- Lazy initialization y logs optimizados para reducir memoria

---

### ✅ 4. Correcciones y Optimizaciones Realizadas

#### Java Version Compatibility

**Problema:** SonarQube 25.9 requiere Java 17, pero el proyecto usaba Java 11
**Solución:**

```dockerfile
# Antes
FROM maven:3.8-openjdk-11 AS build
FROM openjdk:11-jre-slim

# Después
FROM maven:3.9-eclipse-temurin-17 AS build
FROM eclipse-temurin:17-jre-jammy
```

#### Docker Socket Access

**Problema:** Pipeline intentaba conectarse a Docker con TLS sin certificados
**Solución:**

```yaml
# Eliminadas variables de entorno TLS
# DOCKER_HOST, DOCKER_CERT_PATH, DOCKER_TLS_VERIFY

# Usar socket directo montado en pod
volumeMounts:
  - name: docker-sock
    mountPath: /var/run/docker.sock
```

#### RBAC Permissions

**Problema:** Jenkins no podía escalar deployments
**Solución:**

```yaml
# Agregado permiso para subrecurso scale
- apiGroups: ["apps"]
  resources: ["deployments/scale"]
  verbs: ["get", "update", "patch"]
```

#### Image Pull Policy

**Problema:** Kubernetes intentaba descargar imágenes locales de registry
**Solución:**

```yaml
image: user-service:local
imagePullPolicy: Never
```

#### Workspace Cleanup

**Problema:** Permisos de archivos creados por Maven (root)
**Solución:**

```groovy
// Limpiar desde contenedor Maven
container('maven') {
    sh 'rm -rf target || true'
    sh 'mvn clean || true'
}
```

#### Quality Gate Timeout

**Problema:** Pipeline bloqueado esperando webhook de SonarQube
**Solución:**

```groovy
timeout(time: 2, unit: 'MINUTES') {
    def qg = waitForQualityGate()
    // manejo de resultado
}
```

---

### ✅ 5. Estructura del Repositorio

```
ecommerce-microservice-backend-app/
├── Jenkinsfile                    # Pipeline CI/CD principal
├── jenkins-values.yaml            # Configuración Helm para Jenkins
├── sonarqube-values.yaml          # Configuración Helm para SonarQube
├── pom.xml                        # Parent POM multi-módulo
├── compose.yml                    # Docker Compose (desarrollo local)
│
├── k8s-cicd/                      # Manifiestos CI/CD
│   └── jenkins-rbac.yaml          # RBAC para Jenkins
│
├── k8s-minikube/                  # Manifiestos Kubernetes para Minikube
│   ├── 00-namespace.yaml          # Namespace ecommerce
│   ├── 01-zipkin.yaml             # Servicio Zipkin
│   ├── 02-service-discovery.yaml  # Eureka Server
│   ├── 03-api-gateway.yaml        # API Gateway
│   ├── 04-user-service.yaml       # User Service
│   ├── 05-product-service.yaml    # Product Service
│   └── 06-order-service.yaml      # Order Service
│
├── scripts/                       # Scripts de utilidad
│   ├── deploy-minikube.sh         # Deploy manual a Minikube
│   ├── verify-microservices-minikube.sh
│   ├── aws-k3s-deploy.sh          # Deploy a AWS K3s
│   └── ...
│
├── service-discovery/             # Eureka Server
│   ├── Dockerfile
│   ├── pom.xml
│   └── src/
│
├── api-gateway/                   # API Gateway
│   ├── Dockerfile
│   ├── pom.xml
│   └── src/
│
├── user-service/                  # User Management Service
│   ├── Dockerfile
│   ├── pom.xml
│   └── src/
│
├── product-service/               # Product Catalog Service
│   ├── Dockerfile
│   ├── pom.xml
│   └── src/
│
├── order-service/                 # Order Management Service
│   ├── Dockerfile
│   ├── pom.xml
│   └── src/
│
├── payment-service/               # Payment Service (no desplegado)
├── shipping-service/              # Shipping Service (no desplegado)
├── favourite-service/             # Favourite Service (no desplegado)
├── cloud-config/                  # Config Server (no usado en Minikube)
└── proxy-client/                  # Cliente de pruebas

```

---

## 📈 Métricas y Resultados

### Tiempos de Pipeline

| Operación | Modo Individual | Modo BUILD ALL |
|-----------|----------------|----------------|
| Build + Test | 2-3 min | 3-4 min (paralelo) |
| SonarQube Analysis | 1-2 min | N/A |
| Docker Build | 1 min | 1-2 min (paralelo) |
| Deploy | 1-2 min | 5-8 min (secuencial) |
| **Total** | **5-7 min** | **10-15 min** |

### Recursos Utilizados

**Minikube:**

- Memory: ~8-10 GB
- CPU: ~4 cores
- Disk: ~20 GB

**Namespace cicd:**

- Jenkins: 2-4 Gi RAM
- SonarQube: 2 Gi RAM
- PostgreSQL: 1 Gi RAM

**Namespace ecommerce:**

- 6 pods × 768Mi-2Gi = ~5-12 Gi RAM total
- Zipkin adicional

---

## 🔧 Comandos Útiles

### Ver Estado de Todo

```bash
# Pods
kubectl get pods -n ecommerce
kubectl get pods -n cicd

# Deployments
kubectl get deployments -n ecommerce

# Servicios
kubectl get svc -n ecommerce

# Recursos
kubectl top pods -n ecommerce
kubectl top nodes
```

### Acceder a UIs

```bash
# Jenkins
echo "http://$(minikube ip):30800"

# SonarQube
echo "http://$(minikube ip):30900"

# Eureka
echo "http://$(minikube ip):30761"
```

### Ver Logs

```bash
# Logs de servicio específico
kubectl logs -f -n ecommerce -l app=user-service

# Logs de Jenkins
kubectl logs -f jenkins-0 -c jenkins -n cicd

# Logs de SonarQube
kubectl logs -f sonarqube-sonarqube-0 -n cicd
```

### Troubleshooting

```bash
# Describe pod con problemas
kubectl describe pod <POD_NAME> -n ecommerce

# Ver eventos
kubectl get events -n ecommerce --sort-by='.lastTimestamp'

# Restart deployment
kubectl rollout restart deployment/user-service -n ecommerce

# Escalar manualmente
kubectl scale deployment user-service --replicas=1 -n ecommerce
```

---

## 🎓 Tecnologías Utilizadas

### Infraestructura

- **Minikube** - Kubernetes local
- **Helm** - Package manager para Kubernetes
- **Kubectl** - CLI de Kubernetes

### CI/CD

- **Jenkins** - Servidor CI/CD
  - Jenkins Kubernetes Plugin
  - Pipeline declarativo
  - Agents dinámicos en pods
- **SonarQube** - Análisis de calidad de código
  - Community Edition 25.9
  - PostgreSQL backend
  - Jacoco para coverage
- **Docker** - Containerización
  - Multi-stage builds
  - BuildKit

### Microservicios (Spring Boot 2.6.1)

- **Spring Cloud Netflix Eureka** - Service Discovery
- **Spring Cloud Gateway** - API Gateway
- **Spring Data JPA** - Persistencia
- **Zipkin** - Distributed Tracing
- **H2 Database** - Base de datos en memoria (dev)

### Lenguajes y Frameworks

- **Java 17** - Lenguaje principal
- **Maven 3.9** - Build tool
- **Groovy** - Jenkins Pipeline DSL

---

## 📚 Archivos de Configuración Clave

### Jenkinsfile

- Pipeline declarativo
- 2 modos: Individual y BUILD ALL
- Multi-contenedor: Maven, Docker, Kubectl
- Integración con SonarQube
- Deploy automatizado a Kubernetes

### jenkins-values.yaml

```yaml
controller:
  serviceType: NodePort
  nodePort: 30800
  resources:
    requests: { memory: "2Gi", cpu: "1000m" }
    limits: { memory: "4Gi", cpu: "2000m" }
  installPlugins:
    - kubernetes:4252.v6f7c61b_c43e6
    - workflow-aggregator:600.vb_57cdd26fdd7
    - git:5.7.0
    - sonar:2.17.2
persistence:
  enabled: true
  size: 10Gi
```

### sonarqube-values.yaml

```yaml
community:
  enabled: true
service:
  type: NodePort
  nodePort: 30900
postgresql:
  enabled: true
```

### k8s-minikube/*.yaml

- Manifiestos optimizados para Minikube
- Resources con límites conservadores
- imagePullPolicy: Never
- readinessProbe con delays largos
- Environment variables para Eureka y Zipkin

---

## ✅ Checklist de Verificación

- [x] Minikube corriendo con recursos suficientes
- [x] Namespace `cicd` creado
- [x] Namespace `ecommerce` creado
- [x] Jenkins desplegado y accesible
- [x] SonarQube desplegado y accesible
- [x] PostgreSQL funcionando
- [x] RBAC configurado correctamente
- [x] Jenkinsfile funcional
- [x] Pipeline BUILD ALL exitoso
- [x] 6 pods corriendo en namespace ecommerce
- [x] Todos los servicios registrados en Eureka
- [x] Readiness probes pasando
- [x] No hay CrashLoopBackOff
- [x] Imágenes Docker construidas con tag `:local`
- [x] Zipkin recibiendo traces

---

## 🚀 Próximos Pasos Recomendados

### Configuración Adicional

1. **SonarQube Webhook**
   - Configurar webhook en SonarQube: `http://jenkins:8080/sonarqube-webhook/`
   - Para que Quality Gate funcione en tiempo real

2. **Git Webhooks**
   - Configurar webhooks en GitHub/GitLab
   - Trigger automático de pipelines en push

3. **Persistent Databases**
   - Reemplazar H2 con PostgreSQL/MySQL
   - PersistentVolumeClaims para datos

### Mejoras

4. **Monitoring**
   - Desplegar Prometheus + Grafana
   - Dashboards de métricas

5. **Ingress Controller**
   - Nginx Ingress
   - URLs amigables en lugar de NodePort

6. **Security**
   - TLS/SSL con cert-manager
   - Network Policies
   - Pod Security Policies

7. **Escalabilidad**
   - HorizontalPodAutoscaler
   - Multiple replicas de servicios

8. **Testing**
   - Integration tests en pipeline
   - Performance tests con JMeter/Gatling

---

## 📝 Notas Importantes

### Limitaciones Actuales

- Base de datos H2 in-memory (no persistente)
- Single replica por servicio
- No hay TLS/SSL
- NodePort para acceso (no production-ready)
- Minikube single-node (no HA)

### Decisiones de Diseño

- **Java 17**: Requerido por SonarQube 25.9
- **imagePullPolicy: Never**: Imágenes locales, no registry
- **Build en paralelo**: Servicios independientes en compilación
- **Deploy secuencial**: Eureka debe estar primero
- **Resources conservadores**: Para funcionar en laptops

### Archivos Eliminados

- `Guía adicional Taller 2.pdf` (duplicado)
- `Dockerfile.user-service` (cada servicio tiene el suyo)
- `azure-pipelines.yml` (no usado)
- `jenkins/` (Jenkinsfiles obsoletos)
- `*/bin/` (directorios compilados)

---

## 👥 Información del Proyecto

**Curso:** Ingeniería de Software V
**Institución:** ICESI
**Semestre:** 8vo
**Proyecto:** E-commerce Microservice Backend
**Taller:** Taller 2 - CI/CD y Despliegue

---

## 📞 Recursos y Referencias

- [Jenkins Kubernetes Plugin](https://plugins.jenkins.io/kubernetes/)
- [SonarQube Documentation](https://docs.sonarqube.org/)
- [Spring Cloud Netflix](https://spring.io/projects/spring-cloud-netflix)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [Helm Charts](https://helm.sh/docs/)
- [Kubernetes RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)

---

**Fecha de Completación:** Octubre 28, 2025
**Estado:** ✅ Completado y Funcionando
