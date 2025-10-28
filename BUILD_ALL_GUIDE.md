# 🚀 Guía: BUILD ALL - Construir Todos los Microservicios

## 📋 Resumen

El pipeline ahora soporta construir y desplegar **TODOS** los microservicios de una vez o servicios individuales.

## 🎯 Casos de Uso

### Caso 1: Setup Inicial (BUILD ALL)
**Cuándo usarlo**: Primera vez que levantas el proyecto, o cuando reconstruyes todo desde cero.

```bash
Parámetros en Jenkins:
- SERVICE_NAME: ALL
- RUN_SONAR: false (no hace análisis SonarQube en modo ALL)
- DEPLOY_TO_MINIKUBE: true
```

**Lo que hace**:
1. ✅ Construye TODOS los microservicios en **paralelo** (Maven)
2. ✅ Construye TODAS las imágenes Docker en **paralelo**
3. ✅ Despliega respetando dependencias:
   - Primero: `service-discovery` (Eureka)
   - Espera a que Eureka esté READY
   - Luego: resto de servicios en secuencia
4. ✅ Verifica que todos estén desplegados

**Tiempo estimado**: ~10-15 minutos

---

### Caso 2: Modificar UN Microservicio (Individual)
**Cuándo usarlo**: Desarrollo día a día, solo modificaste un servicio.

```bash
Parámetros en Jenkins:
- SERVICE_NAME: user-service (o el que modificaste)
- RUN_SONAR: true
- DEPLOY_TO_MINIKUBE: true
```

**Lo que hace**:
1. ✅ Build + tests del servicio específico
2. ✅ Análisis SonarQube (con coverage)
3. ✅ Quality Gate
4. ✅ Construye imagen Docker
5. ✅ Despliega solo ese servicio
6. ✅ Verifica despliegue

**Tiempo estimado**: ~5-7 minutos

---

## 🔧 Cómo Funciona BUILD ALL

### Fase 1: Build Maven (Paralelo)
```
┌─────────────────────────────────────┐
│  Maven Build (5 servicios en ||)   │
├─────────────────────────────────────┤
│  ├─ service-discovery               │
│  ├─ api-gateway                     │
│  ├─ user-service                    │
│  ├─ product-service                 │
│  └─ order-service                   │
└─────────────────────────────────────┘
```
**No hay dependencias** → Todo en paralelo

### Fase 2: Docker Build (Paralelo)
```
┌─────────────────────────────────────┐
│  Docker Build (5 imágenes en ||)   │
├─────────────────────────────────────┤
│  ├─ service-discovery:local         │
│  ├─ api-gateway:local               │
│  ├─ user-service:local              │
│  ├─ product-service:local           │
│  └─ order-service:local             │
└─────────────────────────────────────┘
```
**No hay dependencias** → Todo en paralelo

### Fase 3: Deploy Kubernetes (Secuencial)
```
┌─────────────────────────────────────┐
│  Kubernetes Deploy (Secuencial)    │
├─────────────────────────────────────┤
│  1. service-discovery (Eureka)     │
│     ↓ espera READY                 │
│     ↓ espera 30s adicionales       │
│  2. api-gateway      ┐              │
│  3. user-service     │ (secuencia) │
│  4. product-service  │              │
│  5. order-service    ┘              │
└─────────────────────────────────────┘
```
**HAY dependencias** → Eureka primero, resto después

---

## 🚀 Paso a Paso: Primera Vez

### 1. Accede a Jenkins
```bash
# Obtén la URL
echo "http://$(minikube ip):30800"

# Abre en navegador
xdg-open "http://$(minikube ip):30800"
```

### 2. Ve al Job
- Click en `ecommerce-pipeline`
- Click en **"Build with Parameters"**

### 3. Configura los Parámetros
```
SERVICE_NAME: ALL
RUN_SONAR: false
DEPLOY_TO_MINIKUBE: true
```

### 4. Click "Build"
Espera ~10-15 minutos. Verás:
- ✅ Build All Services (paralelo)
- ✅ Build All Docker Images (paralelo)
- ✅ Deploy to Minikube (secuencial)
- ✅ Verify Deployment

### 5. Verifica el Resultado
```bash
# Ver todos los pods
kubectl get pods -n ecommerce

# Deberías ver:
# service-discovery-xxx   1/1   Running
# api-gateway-xxx         1/1   Running
# user-service-xxx        1/1   Running
# product-service-xxx     1/1   Running
# order-service-xxx       1/1   Running
# zipkin-xxx              1/1   Running
```

---

## 📊 Comparación

| Aspecto | BUILD ALL | Individual |
|---------|-----------|------------|
| **Tiempo** | 10-15 min | 5-7 min |
| **SonarQube** | ❌ No | ✅ Sí |
| **Tests** | ❌ No | ✅ Sí |
| **Quality Gate** | ❌ No | ✅ Sí |
| **Paralelización** | ✅ Build/Docker | ❌ Secuencial |
| **Cuándo usar** | Setup inicial | Desarrollo diario |

---

## ⚠️ Consideraciones Importantes

### Recursos de Minikube
BUILD ALL construye 5 servicios a la vez:
- **RAM necesaria**: ~8-10 GB para Minikube
- **CPU necesaria**: ~4 cores

Si Minikube se queda sin recursos:
```bash
# Aumentar recursos
minikube delete
minikube start --memory=10240 --cpus=4
```

### Orden de Despliegue
El pipeline **siempre** despliega service-discovery primero porque:
- Es Eureka (service registry)
- Todos los demás servicios intentan registrarse en Eureka
- Si Eureka no está listo, los servicios fallan

### SonarQube en BUILD ALL
**No se ejecuta** análisis de SonarQube en modo ALL porque:
- Sería muy lento (5 análisis secuenciales)
- Usa muchos recursos
- Es mejor analizar servicios uno por uno durante desarrollo

---

## 🔄 Workflows Recomendados

### Workflow 1: Primera Vez
```bash
1. BUILD ALL (setup inicial)
2. Verificar que todo funciona
3. Desarrollo normal con builds individuales
```

### Workflow 2: Desarrollo Diario
```bash
1. Modificas user-service
2. Build individual: SERVICE_NAME=user-service
3. SonarQube analiza solo ese servicio
4. Despliega solo ese servicio
```

### Workflow 3: Cambios Grandes
```bash
1. Modificas múltiples servicios
2. BUILD ALL para reconstruir todo
3. Verificar integración completa
```

---

## 🐛 Troubleshooting

### Problema: "error: no objects passed to scale"
**Causa**: Los deployments no existen aún
**Solución**:
```bash
kubectl apply -f k8s-minikube/
```

### Problema: Pipeline muy lento
**Causa**: Minikube sin suficientes recursos
**Solución**:
```bash
# Ver uso actual
kubectl top nodes
kubectl top pods -n cicd

# Aumentar recursos
minikube stop
minikube config set memory 10240
minikube config set cpus 4
minikube start
```

### Problema: service-discovery no arranca
**Causa**: Eureka necesita más tiempo
**Solución**: El pipeline ya espera 30s extra, pero puedes:
```bash
# Ver logs
kubectl logs -n ecommerce -l app=service-discovery

# Esperar manualmente
kubectl wait --for=condition=ready pod -l app=service-discovery -n ecommerce --timeout=600s
```

---

## 📝 Notas Técnicas

### Por qué Build en Paralelo es Seguro
Los microservicios son **independientes** en tiempo de compilación:
- Cada uno tiene su propio `pom.xml`
- No comparten código durante el build
- No hay dependencias entre módulos Maven

### Por qué Deploy es Secuencial
Los microservicios tienen **dependencias en runtime**:
- Todos necesitan Eureka para registrarse
- Si Eureka no está, los servicios entran en retry loop
- El orden correcto evita errores de conexión

### Imágenes Docker Etiquetadas
Cada imagen se etiqueta 3 veces:
```
user-service:latest     # Tag general
user-service:local      # Para Kubernetes (imagePullPolicy: Never)
user-service:15         # Build number (historial)
```

---

## ✅ Checklist de Éxito

Después de BUILD ALL, verifica:

- [ ] 6 pods corriendo en namespace ecommerce
- [ ] service-discovery registrado en Eureka
- [ ] Otros servicios registrados en Eureka
- [ ] Todos los pods en estado READY
- [ ] No hay CrashLoopBackOff
- [ ] Logs sin errores críticos

```bash
# Checklist automático
kubectl get pods -n ecommerce
kubectl logs -n ecommerce -l app=service-discovery --tail=10
kubectl logs -n ecommerce -l app=user-service --tail=10
```

---

## 🎓 Próximos Pasos

Después de completar BUILD ALL exitosamente:

1. ✅ **Configura SonarQube webhook** (para builds individuales)
2. ✅ **Prueba build individual** de user-service con SonarQube
3. ✅ **Configura webhooks Git** (para CI automático)
4. ✅ **Agrega health checks** a tu aplicación
5. ✅ **Configura monitoring** (Prometheus + Grafana)
