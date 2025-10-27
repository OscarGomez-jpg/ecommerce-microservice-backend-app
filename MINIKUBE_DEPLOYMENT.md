# Despliegue en Minikube - Guía Completa

## Resumen Ejecutivo

Despliegue exitoso de 6 microservicios Spring Boot en Minikube con optimizaciones que redujeron el tiempo de inicio de **9+ minutos a ~3 minutos**.

## Características del Despliegue

- **Plataforma**: Minikube (Kubernetes local)
- **Servicios desplegados**: 6 microservicios + Zipkin
- **Tiempo de inicio**: ~3 minutos (vs 9+ minutos sin optimización)
- **Recursos**: 4 CPUs, 12GB RAM
- **Estabilidad**: 0 reinicios, todos los pods Ready

## Prerequisitos

```bash
# Minikube instalado
minikube version

# kubectl instalado
kubectl version --client

# Docker instalado
docker version
```

## Configuración de Minikube

### 1. Crear cluster con recursos suficientes

```bash
# Eliminar cluster anterior si existe
minikube delete

# Crear nuevo cluster con recursos optimizados
minikube start --cpus=4 --memory=12g --disk-size=40g --driver=docker

# Habilitar metrics-server para monitoreo
minikube addons enable metrics-server
```

### 2. Construir imágenes locales

```bash
# Configurar Docker para usar daemon de Minikube
eval $(minikube docker-env)

# Construir todas las imágenes
for service in service-discovery api-gateway user-service product-service order-service; do
  docker build -t ${service}:local -f ${service}/Dockerfile ${service}/
done
```

## Optimizaciones Aplicadas

### 1. Variables de Entorno de Spring Boot

Agregadas a todos los manifiestos:

```yaml
env:
- name: SPRING_JPA_SHOW_SQL
  value: "false"  # Deshabilitar logging SQL
- name: LOGGING_LEVEL_ORG_SPRINGFRAMEWORK
  value: "WARN"  # Reducir logging
- name: LOGGING_LEVEL_ORG_HIBERNATE
  value: "WARN"  # Reducir logging Hibernate
- name: SPRING_MAIN_LAZY_INITIALIZATION
  value: "true"  # Lazy loading de beans
- name: JAVA_TOOL_OPTIONS
  value: "-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:+TieredCompilation -XX:TieredStopAtLevel=1"
```

**Impacto:**
- `SPRING_MAIN_LAZY_INITIALIZATION=true`: Reduce tiempo de inicio en ~40%
- `TieredCompilation`: JVM inicia más rápido con compilación optimizada
- Logging reducido: Menos I/O durante inicio

### 2. Health Checks Ajustados

```yaml
readinessProbe:
  httpGet:
    path: /service-name/actuator/health  # Con context-path correcto
    port: 8080
  initialDelaySeconds: 120  # 2 minutos de gracia
  periodSeconds: 10
  failureThreshold: 60  # Hasta 12 minutos total
  timeoutSeconds: 5
```

**Importante:**
- NO usar liveness probes (matan pods durante startup lento)
- `initialDelaySeconds`: 120s para servicios Spring Boot
- `failureThreshold: 60`: Permite hasta 12 minutos total
- Context-path correcto: `/user-service/actuator/health` (no `/actuator/health`)

### 3. Recursos por Pod

```yaml
resources:
  requests:
    memory: "768Mi"
    cpu: "100m-200m"
  limits:
    memory: "2Gi"  # Crítico: evita OOMKilled
    cpu: "300m-500m"
```

**Clave:** Límite de 2Gi de RAM previene OOMKilled durante inicio.

## Despliegue Paso a Paso

### 1. Crear namespace

```bash
kubectl apply -f k8s-minikube/00-namespace.yaml
```

### 2. Desplegar servicios core

```bash
# Zipkin y Service Discovery primero
kubectl apply -f k8s-minikube/01-zipkin.yaml
kubectl apply -f k8s-minikube/02-service-discovery.yaml

# Esperar que estén Ready (~3 minutos)
kubectl wait --for=condition=ready pod -l app=service-discovery -n ecommerce --timeout=300s
```

### 3. Desplegar servicios de negocio

```bash
kubectl apply -f k8s-minikube/03-api-gateway.yaml
kubectl apply -f k8s-minikube/04-user-service.yaml
kubectl apply -f k8s-minikube/05-product-service.yaml
kubectl apply -f k8s-minikube/06-order-service.yaml

# Esperar que todos estén Ready (~3 minutos)
kubectl get pods -n ecommerce -w
```

## Verificación

### 1. Estado de Pods

```bash
kubectl get pods -n ecommerce
```

**Salida esperada:**
```
NAME                                 READY   STATUS    RESTARTS   AGE
api-gateway-xxx                      1/1     Running   0          3m
order-service-xxx                    1/1     Running   0          3m
product-service-xxx                  1/1     Running   0          3m
service-discovery-xxx                1/1     Running   0          6m
user-service-xxx                     1/1     Running   0          3m
zipkin-xxx                           1/1     Running   0          6m
```

### 2. Servicios en Eureka

```bash
curl -s http://$(minikube ip):30761/eureka/apps | grep "<name>"
```

**Salida esperada:**
- API-GATEWAY
- USER-SERVICE
- PRODUCT-SERVICE
- ORDER-SERVICE

### 3. Probar Endpoints

```bash
MINIKUBE_IP=$(minikube ip)

# User Service
curl http://$MINIKUBE_IP:30080/user-service/api/users

# Product Service
curl http://$MINIKUBE_IP:30080/product-service/api/products

# Eureka Dashboard
open http://$MINIKUBE_IP:30761

# Zipkin Dashboard
open http://$MINIKUBE_IP:30411
```

### 4. Uso de Recursos

```bash
kubectl top pods -n ecommerce
```

**Uso típico:**
- CPU: 3-18m por servicio
- RAM: 1.2-1.7GB por servicio
- Total: ~7GB de 12GB disponibles

## Troubleshooting

### Problema: Pods en CrashLoopBackOff

**Causa:** Liveness probes matando pods durante inicio lento
**Solución:** Eliminar liveness probes, solo usar readiness

### Problema: Pods OOMKilled

**Causa:** Límite de memoria muy bajo (1Gi)
**Solución:** Aumentar a 2Gi en limits

### Problema: Health checks 404

**Causa:** Falta context-path en la ruta
**Solución:** Usar `/service-name/actuator/health` no `/actuator/health`

### Problema: Rolling updates atascados

**Causa:** Pods duplicados compitiendo por recursos
**Solución:** Escalar a 0 y luego a 1

```bash
kubectl scale deployment user-service --replicas=0 -n ecommerce
kubectl scale deployment user-service --replicas=1 -n ecommerce
```

### Problema: API Server se cae

**Causa:** Recursos insuficientes en Minikube
**Solución:** Recrear con más RAM

```bash
minikube delete
minikube start --cpus=4 --memory=12g --driver=docker
```

## Endpoints Disponibles

| Servicio | Puerto NodePort | URL |
|----------|----------------|-----|
| Eureka Dashboard | 30761 | http://$(minikube ip):30761 |
| API Gateway | 30080 | http://$(minikube ip):30080 |
| Zipkin | 30411 | http://$(minikube ip):30411 |
| User Service | - | http://$(minikube ip):30080/user-service/api/* |
| Product Service | - | http://$(minikube ip):30080/product-service/api/* |
| Order Service | - | http://$(minikube ip):30080/order-service/api/* |

## Comparación: Docker Compose vs Minikube

| Aspecto | Docker Compose | Minikube |
|---------|---------------|----------|
| Tiempo de inicio | 1-2 min | 3 min (optimizado) |
| Recursos | ~2.3GB RAM | ~7GB RAM |
| Complejidad | Simple (1 archivo) | Media (múltiples YAMLs) |
| Producción | ❌ No | ✅ Simula K8s real |
| Auto-healing | ❌ No | ✅ Sí |
| Escalabilidad | ❌ No | ✅ Sí |
| Monitoreo | Básico | Avanzado (metrics-server) |

## Resultados Finales

✅ **Todos los servicios funcionando correctamente**
✅ **Tiempo de inicio reducido de 9+ min a ~3 min**
✅ **0 reinicios de pods**
✅ **Registros exitosos en Eureka**
✅ **Endpoints respondiendo correctamente**
✅ **Uso eficiente de recursos (CPU <20m por servicio)**

## Scripts de Utilidad

### Redeploy completo

```bash
# Eliminar todo
kubectl delete namespace ecommerce

# Redeplegar
kubectl apply -f k8s-minikube/
```

### Ver logs en tiempo real

```bash
# Logs de un servicio
kubectl logs -f deployment/user-service -n ecommerce

# Logs de todos los pods
kubectl logs -f -l app=user-service -n ecommerce
```

### Acceder a un pod

```bash
kubectl exec -it deployment/user-service -n ecommerce -- /bin/sh
```

## Conclusiones

El despliegue en Minikube fue exitoso después de aplicar optimizaciones clave:

1. **Lazy initialization**: Reduce carga de inicio
2. **JVM tuning**: Compilación más rápida
3. **Health checks correctos**: Sin liveness probes
4. **Recursos suficientes**: 2Gi RAM por servicio, 12GB total cluster
5. **Context-paths correctos**: Rutas con prefijo de servicio

**Tiempo total de despliegue:** ~6 minutos (vs 9+ minutos con fallos constantes).

## Referencias

- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [Spring Boot on Kubernetes](https://spring.io/guides/gs/spring-boot-kubernetes/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
