# 🚀 Guía de Uso del Pipeline de Jenkins

## 📋 Requisitos Previos

✅ Jenkins desplegado en Minikube (namespace: cicd)
✅ SonarQube desplegado en Minikube (namespace: cicd)
✅ Microservicios desplegados en Minikube (namespace: ecommerce)
✅ ServiceAccount y permisos RBAC configurados

---

## 🔧 Configuración Inicial

### 1. Aplicar Permisos RBAC

```bash
# Crear ServiceAccount y permisos para Jenkins
kubectl apply -f k8s-cicd/jenkins-rbac.yaml

# Verificar
kubectl get sa jenkins -n cicd
kubectl get clusterrole jenkins-deploy
kubectl get clusterrolebinding jenkins-deploy
```

### 2. Configurar Jenkins

1. **Acceder a Jenkins**: http://192.168.49.2:30800
2. **Credenciales**: admin / 0cIluLpqXNK15U3UwV22F6

3. **Configurar SonarQube** (si no está configurado):
   - Ir a: Manage Jenkins → Configure System
   - Buscar "SonarQube servers"
   - Add SonarQube:
     - Name: `SonarQube`
     - Server URL: `http://sonarqube-sonarqube:9000`
     - Server authentication token: (crear en SonarQube primero)

4. **Crear Token en SonarQube**:
   - Acceder a: http://192.168.49.2:30900
   - Login: admin / [nueva contraseña]
   - My Account → Security → Generate Token
   - Nombre: `jenkins-integration`
   - Copiar el token generado

5. **Agregar Token en Jenkins**:
   - Manage Jenkins → Credentials
   - (global) → Add Credentials
   - Kind: Secret text
   - Secret: [token de SonarQube]
   - ID: `sonarqube-token`

---

## 📝 Crear el Pipeline Job

### Opción 1: Pipeline desde SCM (Recomendado)

1. **New Item** → Pipeline → Nombre: `ecommerce-microservices-pipeline`
2. **Pipeline Section**:
   - Definition: `Pipeline script from SCM`
   - SCM: Git
   - Repository URL: [URL de tu repo]
   - Branch: `*/master`
   - Script Path: `Jenkinsfile`
3. **Save**

### Opción 2: Pipeline Script Directo

1. **New Item** → Pipeline → Nombre: `ecommerce-microservices-pipeline`
2. **Pipeline Section**:
   - Definition: `Pipeline script`
   - Script: [Copiar contenido del Jenkinsfile]
3. **Save**

---

## 🎯 Ejecutar el Pipeline

### Método 1: Desde la Interfaz Web

1. Ir al job: `ecommerce-microservices-pipeline`
2. Click en **"Build with Parameters"**
3. Seleccionar:
   - **SERVICE_NAME**: Elegir microservicio (e.g., `user-service`)
   - **RUN_SONAR**: ✅ (para análisis de código)
   - **DEPLOY_TO_MINIKUBE**: ✅ (para desplegar después de construir)
4. Click en **"Build"**

### Método 2: Desde Jenkins CLI

```bash
# Construir user-service con SonarQube y despliegue
java -jar jenkins-cli.jar -s http://192.168.49.2:30800 \
  -auth admin:0cIluLpqXNK15U3UwV22F6 \
  build ecommerce-microservices-pipeline \
  -p SERVICE_NAME=user-service \
  -p RUN_SONAR=true \
  -p DEPLOY_TO_MINIKUBE=true
```

---

## 🔍 Etapas del Pipeline

### 1. **Checkout**
- Clona el código del repositorio

### 2. **Build & Test**
- Ejecuta `mvn clean package -DskipTests`
- Genera el JAR del microservicio

### 3. **Unit Tests**
- Ejecuta `mvn test`
- Genera reportes de tests
- Publica resultados en Jenkins

### 4. **SonarQube Analysis**
- Analiza calidad de código
- Detecta bugs, vulnerabilities, code smells
- Envía resultados a SonarQube

### 5. **Quality Gate**
- Espera resultado del Quality Gate de SonarQube
- Advierte si no pasa (no falla el build)

### 6. **Build Docker Image**
- Construye imagen Docker del microservicio
- Etiqueta con `latest` y número de build
- Usa Docker daemon de Minikube

### 7. **Deploy to Minikube**
- Escala deployment a 0 (libera recursos)
- Escala deployment a 1 con nueva imagen
- Espera a que el rollout complete

### 8. **Verify Deployment**
- Verifica que el pod esté READY
- Muestra estado del deployment
- Confirma que el servicio funciona

---

## 📊 Ver Resultados

### En Jenkins

- **Console Output**: Ver logs completos de la ejecución
- **Test Results**: Ver tests unitarios
- **SonarQube**: Link directo al análisis

### En SonarQube

- Acceder a: http://192.168.49.2:30900
- Ver proyecto: `user-service`, `product-service`, etc.
- Métricas:
  - **Bugs**: Errores en el código
  - **Vulnerabilities**: Problemas de seguridad
  - **Code Smells**: Código mejorable
  - **Coverage**: Cobertura de tests
  - **Duplications**: Código duplicado

### En Minikube

```bash
# Ver pods desplegados
kubectl get pods -n ecommerce

# Ver logs del microservicio
kubectl logs -f deployment/user-service -n ecommerce

# Ver estado del rollout
kubectl rollout status deployment/user-service -n ecommerce

# Ver historial de rollouts
kubectl rollout history deployment/user-service -n ecommerce
```

---

## 🛠️ Personalizar el Pipeline

### Agregar Notificaciones

Agregar al final del Jenkinsfile:

```groovy
post {
    success {
        // Slack
        slackSend (
            color: '#00FF00',
            message: "✅ Build exitoso: ${params.SERVICE_NAME} #${BUILD_NUMBER}"
        )
    }
    failure {
        // Email
        emailext (
            subject: "❌ Build falló: ${params.SERVICE_NAME} #${BUILD_NUMBER}",
            body: "Ver detalles en: ${BUILD_URL}",
            to: "team@example.com"
        )
    }
}
```

### Agregar Tests de Integración

```groovy
stage('Integration Tests') {
    steps {
        container('maven') {
            dir(params.SERVICE_NAME) {
                sh 'mvn verify -Pintegration-tests'
            }
        }
    }
}
```

### Agregar Escaneo de Seguridad

```groovy
stage('Security Scan') {
    steps {
        container('maven') {
            sh '''
                mvn org.owasp:dependency-check-maven:check
            '''
        }
    }
}
```

---

## 🔄 Pipeline Automático con Webhooks

### Configurar Webhook en Git

1. **GitHub/GitLab Settings** → Webhooks
2. **Payload URL**: `http://192.168.49.2:30800/github-webhook/`
3. **Content type**: `application/json`
4. **Events**: `Push events`, `Pull request`

### Configurar en Jenkins

1. Job → **Configure**
2. **Build Triggers**:
   - ✅ GitHub hook trigger for GITScm polling
   - ✅ Poll SCM: `H/5 * * * *` (backup cada 5 min)

---

## 🎓 Ejemplos de Uso

### Ejemplo 1: Construir user-service con análisis completo

```bash
# Via interfaz web
SERVICE_NAME: user-service
RUN_SONAR: true
DEPLOY_TO_MINIKUBE: true
```

**Resultado esperado**:
- ✅ Código compilado
- ✅ Tests ejecutados
- ✅ Análisis de SonarQube completado
- ✅ Imagen Docker construida
- ✅ Desplegado en Minikube

### Ejemplo 2: Solo construir sin desplegar

```bash
SERVICE_NAME: product-service
RUN_SONAR: true
DEPLOY_TO_MINIKUBE: false
```

**Uso**: Validar cambios sin afectar el ambiente

### Ejemplo 3: Despliegue rápido sin análisis

```bash
SERVICE_NAME: order-service
RUN_SONAR: false
DEPLOY_TO_MINIKUBE: true
```

**Uso**: Hotfix urgente

---

## 🐛 Troubleshooting

### Error: "Cannot connect to Docker daemon"

**Solución**: Verificar que el pod de Jenkins tenga acceso al socket de Docker

```bash
kubectl exec -it jenkins-0 -n cicd -c jenkins -- ls -la /var/run/docker.sock
```

### Error: "Permission denied" al desplegar

**Solución**: Verificar RBAC

```bash
kubectl auth can-i create deployments --as=system:serviceaccount:cicd:jenkins -n ecommerce
```

### Error: "Quality Gate timeout"

**Solución**: SonarQube puede estar lento

```bash
# Verificar SonarQube
kubectl logs sonarqube-sonarqube-0 -n cicd

# Aumentar timeout en Jenkinsfile
timeout(time: 10, unit: 'MINUTES') {
    waitForQualityGate()
}
```

### Pipeline se queda esperando agente

**Solución**: Verificar que Jenkins puede crear pods

```bash
# Ver eventos
kubectl get events -n cicd --sort-by='.lastTimestamp'

# Ver logs de Jenkins controller
kubectl logs jenkins-0 -c jenkins -n cicd | grep -i kubernetes
```

---

## 📚 Recursos Adicionales

- [Jenkinsfile Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Kubernetes Plugin](https://plugins.jenkins.io/kubernetes/)
- [SonarQube Scanner for Jenkins](https://docs.sonarqube.org/latest/analysis/scan/sonarscanner-for-jenkins/)
- [Docker Pipeline Plugin](https://plugins.jenkins.io/docker-workflow/)

---

## ✅ Checklist de Despliegue

- [ ] Jenkins accesible en http://192.168.49.2:30800
- [ ] SonarQube accesible en http://192.168.49.2:30900
- [ ] RBAC configurado (`kubectl apply -f k8s-cicd/jenkins-rbac.yaml`)
- [ ] Token de SonarQube creado
- [ ] Token agregado a Jenkins credentials
- [ ] Pipeline job creado
- [ ] Primer build exitoso
- [ ] Microservicio desplegado correctamente
- [ ] Resultados visibles en SonarQube

¡Tu pipeline CI/CD está listo para usar! 🎉
