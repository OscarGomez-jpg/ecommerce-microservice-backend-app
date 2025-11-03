# 🌍 Guía de Ambientes - Ecommerce Microservices

## Configuración de Ambientes

Este proyecto utiliza **dos ambientes** gestionados automáticamente por Jenkins basado en la rama Git:

### 📊 Tabla de Ambientes

| Ambiente | Rama Git | Namespace K8s | Trigger | Despliegue | Tests |
|----------|----------|---------------|---------|------------|-------|
| **Development** | `dev` | `ecommerce-dev` | Automático (push) | Opcional | Build + Unit + SonarQube |
| **Production** | `master` | `ecommerce-prod` | Manual/Automático | Siempre | Full Pipeline + E2E + Load |

---

## 🔄 Flujo por Ambiente

### **Ambiente DEV (rama `dev`)**

**Objetivo:** Validación continua de código y calidad

**Trigger:**
- ✅ Automático al hacer `git push` a rama `dev`
- ✅ GitHub Webhook → Jenkins

**Pipeline ejecuta:**
1. ✅ **Build** - Compilación de todos los servicios
2. ✅ **Unit Tests** - Tests unitarios con JUnit
3. ✅ **SonarQube Analysis** - Análisis de código + cobertura
4. ⚠️ **Deploy** - Solo si `DEPLOY_TO_MINIKUBE=true` (opcional)
5. ❌ **E2E/Load Tests** - No se ejecutan por defecto

**Namespace:** `ecommerce-dev`

**Caso de uso:**
```bash
# Desarrollador hace cambios
git checkout dev
git add .
git commit -m "feat: add new endpoint"
git push origin dev
# → Jenkins ejecuta automáticamente: Build + Tests + SonarQube
```

---

### **Ambiente PRODUCTION (rama `master`)**

**Objetivo:** Despliegue completo y validación final

**Trigger:**
- ✅ Manual desde Jenkins UI
- ✅ Automático al hacer `git push` a `master` (si webhook configurado)
- ✅ Automático al hacer merge de `dev` → `master`

**Pipeline ejecuta:**
1. ✅ **Build** - Compilación de todos los servicios
2. ✅ **Unit Tests** - Tests unitarios
3. ✅ **SonarQube Analysis** - Análisis completo
4. ✅ **Docker Build** - Construcción de imágenes
5. ✅ **Deploy to Minikube** - Despliegue en `ecommerce-prod`
6. ✅ **Populate Test Data** - Datos de prueba
7. ✅ **E2E Tests (Cypress)** - Tests end-to-end
8. ✅ **Load Tests (Locust)** - Tests de carga

**Namespace:** `ecommerce-prod`

**Caso de uso:**
```bash
# Merge a producción
git checkout master
git merge dev
git push origin master
# → Jenkins ejecuta full pipeline + deploy
```

---

## 🚀 Configuración Inicial

### 1. Crear namespaces en Kubernetes

```bash
kubectl apply -f k8s/namespaces.yaml
```

Esto crea:
- `ecommerce-dev`
- `ecommerce-prod`

### 2. Configurar Jenkins Multibranch Pipeline

1. En Jenkins, crear un **Multibranch Pipeline**
2. Configurar el repositorio Git
3. Agregar credenciales de GitHub
4. Jenkins detectará automáticamente:
   - Rama `dev` → Pipeline DEV
   - Rama `master` → Pipeline PROD

### 3. Configurar GitHub Webhook (opcional para auto-trigger)

En tu repositorio de GitHub:

1. Ve a **Settings → Webhooks → Add webhook**
2. Configura:
   ```
   Payload URL: http://<JENKINS_URL>/github-webhook/
   Content type: application/json
   Events: Just the push event
   ```
3. Guarda

Ahora cada `git push` activará el pipeline automáticamente.

---

## 📋 Parámetros de Pipeline

### **Parámetros disponibles:**

| Parámetro | Valores | Default | Descripción |
|-----------|---------|---------|-------------|
| `SERVICE_NAME` | ALL, user-service, product-service, etc. | ALL | Servicio a construir |
| `RUN_SONAR` | true/false | true | Ejecutar SonarQube |
| `DEPLOY_TO_MINIKUBE` | true/false | - | Desplegar (auto en prod) |
| `RUN_E2E_TESTS` | true/false | false | Tests E2E Cypress |
| `RUN_LOAD_TESTS` | true/false | false | Tests carga Locust |

### **Comportamiento por ambiente:**

#### **DEV (rama `dev`):**
- `DEPLOY_TO_MINIKUBE`: Respeta el parámetro (false por defecto)
- `RUN_E2E_TESTS`: Respeta el parámetro (false por defecto)
- `RUN_LOAD_TESTS`: Respeta el parámetro (false por defecto)

#### **PROD (rama `master`):**
- `DEPLOY_TO_MINIKUBE`: Siempre true (ignora parámetro)
- `RUN_E2E_TESTS`: Respeta el parámetro
- `RUN_LOAD_TESTS`: Respeta el parámetro

---

## 🔍 Verificación de Despliegues

### Ver pods en cada ambiente:

```bash
# Ambiente DEV
kubectl get pods -n ecommerce-dev

# Ambiente PROD
kubectl get pods -n ecommerce-prod
```

### Acceder a servicios:

```bash
# DEV - NodePort base: 30100-30199
kubectl get services -n ecommerce-dev

# PROD - NodePort base: 30080 (actual)
kubectl get services -n ecommerce-prod
```

---

## 🛠️ Casos de Uso Comunes

### **Desarrollo diario:**

```bash
# 1. Crear rama de feature
git checkout dev
git checkout -b feature/new-endpoint

# 2. Hacer cambios
# ... editar código ...

# 3. Commit y push a dev
git checkout dev
git merge feature/new-endpoint
git push origin dev

# ✅ Jenkins ejecuta automáticamente: Build + Tests + SonarQube
```

### **Deploy a producción:**

```bash
# 1. Verificar que dev está OK (tests pasando)
# 2. Merge a master
git checkout master
git merge dev
git push origin master

# ✅ Jenkins ejecuta: Full pipeline + Deploy a ecommerce-prod
```

### **Rollback:**

```bash
# Si hay problema en prod, rollback del deployment
kubectl rollout undo deployment/api-gateway -n ecommerce-prod
kubectl rollout undo deployment/product-service -n ecommerce-prod
# etc...
```

---

## 📊 Reportes

### **SonarQube:**
- URL: `http://sonarqube-sonarqube:9000`
- Proyectos separados por servicio
- Análisis en cada push (dev) y deploy (prod)

### **Cypress (E2E):**
- Reportes en: Jenkins → Build Artifacts → `tests/e2e/cypress/reports/`
- HTML interactivo con resultados detallados

### **Locust (Load Tests):**
- Reportes en: Jenkins → Build Artifacts → `tests/performance/reports/`
- Métricas de rendimiento, errores, percentiles

---

## 🔐 Buenas Prácticas

### **Rama DEV:**
- ✅ Hacer commits frecuentes
- ✅ Validar que tests pasen antes de merge a master
- ✅ Revisar reportes de SonarQube
- ❌ No hacer deploy a producción directamente desde dev

### **Rama MASTER:**
- ✅ Solo hacer merge desde dev (no commits directos)
- ✅ Validar full pipeline antes de declarar release
- ✅ Ejecutar E2E y Load tests
- ✅ Documentar cambios (changelog, release notes)

### **Namespaces:**
- ✅ Mantener separados dev y prod
- ✅ No hacer cambios manuales en prod (usar pipeline)
- ✅ Backup de configuraciones importantes

---

## 🚨 Troubleshooting

### Pipeline no se activa automáticamente

**Causa:** Webhook no configurado

**Solución:**
```bash
# Verificar webhook en GitHub
# Settings → Webhooks → Recent Deliveries
# Debe mostrar requests exitosos (200)
```

### Servicios no se despliegan en namespace correcto

**Causa:** Variable K8S_NAMESPACE no se está usando

**Solución:**
```bash
# Verificar en Console Output del build:
# Debe mostrar: "Namespace K8s: ecommerce-dev" o "ecommerce-prod"
```

### Tests de SonarQube no muestran cobertura

**Causa:** Jacoco no configurado en pom.xml

**Solución:**
```bash
# Verificar que cada pom.xml tiene el plugin jacoco-maven-plugin
# Ver pom.xml de cada microservicio
```

---

## 📚 Referencias

- [Jenkins Multibranch Pipeline](https://www.jenkins.io/doc/book/pipeline/multibranch/)
- [Kubernetes Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)
- [GitHub Webhooks](https://docs.github.com/en/developers/webhooks-and-events/webhooks)
- [SonarQube Documentation](https://docs.sonarqube.org/)
