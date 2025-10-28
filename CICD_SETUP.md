# 🚀 CI/CD en Minikube - Jenkins + SonarQube

## 📊 Estado del Despliegue

✅ **Jenkins**: Desplegado y funcionando
✅ **SonarQube**: Desplegado y funcionando
✅ **PostgreSQL**: Base de datos de SonarQube operativa

---

## 🔐 Credenciales de Acceso

### Jenkins

**URL**: <http://192.168.49.2:30800>

**Credenciales**:

- Usuario: `admin`
- Contraseña: `0cIluLpqXNK15U3UwV22F6`

**Obtener la contraseña nuevamente**:

```bash
kubectl exec --namespace cicd -it svc/jenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password && echo
```

### SonarQube

**URL**: <http://192.168.49.2:30900>

**Credenciales Iniciales**:

- Usuario: `admin`
- Contraseña: `admin`

⚠️ **IMPORTANTE**: SonarQube te pedirá cambiar la contraseña en el primer login.

---

## 🏗️ Arquitectura Desplegada

```
┌─────────────────── Minikube Cluster ───────────────────┐
│                                                          │
│  Namespace: cicd                                         │
│  ┌────────────────────────────────────────────────┐    │
│  │                                                 │    │
│  │   Jenkins (NodePort 30800)                     │    │
│  │   ├─ Controller: 2Gi RAM, 1 CPU                │    │
│  │   ├─ Plugins: k8s, git, sonar, docker          │    │
│  │   └─ Persistent Volume: 10Gi                   │    │
│  │                                                 │    │
│  │   SonarQube (NodePort 30900)                   │    │
│  │   ├─ Server: 2Gi RAM, 1 CPU                    │    │
│  │   ├─ Edition: Community (free)                 │    │
│  │   └─ Persistent Volume: 10Gi                   │    │
│  │                                                 │    │
│  │   PostgreSQL                                    │    │
│  │   ├─ Database: sonarqube                       │    │
│  │   ├─ 1Gi RAM, 500m CPU                         │    │
│  │   └─ Persistent Volume: 10Gi                   │    │
│  │                                                 │    │
│  └────────────────────────────────────────────────┘    │
│                                                          │
│  Namespace: ecommerce                                    │
│  ┌────────────────────────────────────────────────┐    │
│  │  Microservicios:                                │    │
│  │  - service-discovery (Eureka)                   │    │
│  │  - api-gateway                                  │    │
│  │  - user-service                                 │    │
│  │  - product-service                              │    │
│  │  - order-service                                │    │
│  │  - zipkin                                       │    │
│  └────────────────────────────────────────────────┘    │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

---

## 🔧 Comandos Útiles

### Verificar Estado

```bash
# Ver todos los pods de CI/CD
kubectl get pods -n cicd

# Ver servicios expuestos
kubectl get svc -n cicd

# Ver logs de Jenkins
kubectl logs -f jenkins-0 -c jenkins -n cicd

# Ver logs de SonarQube
kubectl logs -f sonarqube-sonarqube-0 -n cicd

# Ver releases de Helm
helm list -n cicd
```

### Acceder a las Aplicaciones

```bash
# Obtener IP de Minikube
MINIKUBE_IP=$(minikube ip)

# Jenkins
echo "Jenkins: http://$MINIKUBE_IP:30800"

# SonarQube
echo "SonarQube: http://$MINIKUBE_IP:30900"

# Abrir en navegador (Linux)
xdg-open "http://$MINIKUBE_IP:30800"  # Jenkins
xdg-open "http://$MINIKUBE_IP:30900"  # SonarQube
```

### Gestión de Helm

```bash
# Actualizar repositorios
helm repo update

# Ver configuración actual de Jenkins
helm get values jenkins -n cicd

# Ver configuración actual de SonarQube
helm get values sonarqube -n cicd

# Actualizar configuración (si modificas los values.yaml)
helm upgrade jenkins jenkins/jenkins -n cicd -f jenkins-values.yaml
helm upgrade sonarqube sonarqube/sonarqube -n cicd -f sonarqube-values.yaml

# Desinstalar (si necesitas empezar de cero)
helm uninstall jenkins -n cicd
helm uninstall sonarqube -n cicd
```

---

## 📝 Configuración Inicial

### 1. Configurar Jenkins

1. Accede a <http://192.168.49.2:30800>
2. Login con las credenciales proporcionadas
3. Instala plugins recomendados (si no están instalados)
4. Configura Kubernetes Cloud:
   - Manage Jenkins → Clouds → New Cloud → Kubernetes
   - Kubernetes URL: `https://kubernetes.default`
   - Jenkins URL: `http://jenkins:8080`
   - Namespace: `cicd`

### 2. Configurar SonarQube

1. Accede a <http://192.168.49.2:30900>
2. Login con `admin/admin`
3. Cambia la contraseña cuando se te solicite
4. Crea un token para Jenkins:
   - User → My Account → Security
   - Generate Token: `jenkins-integration`
   - Guarda el token generado

### 3. Conectar Jenkins con SonarQube

1. En Jenkins: Manage Jenkins → Credentials
2. Add Credentials:
   - Kind: Secret text
   - Secret: [Token de SonarQube]
   - ID: `sonarqube-token`
3. Manage Jenkins → Configure System
4. SonarQube servers:
   - Name: `SonarQube`
   - Server URL: `http://sonarqube-sonarqube:9000`
   - Server authentication token: `sonarqube-token`

---

## 🚀 Próximos Pasos

1. ✅ **Jenkins y SonarQube operativos**
2. 📋 **Crear pipeline para user-service** (ver Jenkinsfile en el repo)
3. 🔄 **Configurar webhooks** para builds automáticos
4. 📊 **Configurar Quality Gates** en SonarQube
5. 🐳 **Pipeline para construir imágenes Docker** en Minikube
6. 🚢 **Pipeline de despliegue** automático a namespace ecommerce

---

## 🐛 Troubleshooting

### Jenkins no arranca

```bash
# Ver logs
kubectl logs jenkins-0 -c jenkins -n cicd

# Verificar recursos
kubectl top pods -n cicd

# Reiniciar pod
kubectl delete pod jenkins-0 -n cicd
```

### SonarQube no arranca

```bash
# Ver logs
kubectl logs sonarqube-sonarqube-0 -n cicd

# Verificar PostgreSQL
kubectl logs sonarqube-postgresql-0 -n cicd

# Verificar conectividad
kubectl exec -it sonarqube-sonarqube-0 -n cicd -- curl -v sonarqube-postgresql:5432
```

### Problemas de almacenamiento

```bash
# Ver PVCs
kubectl get pvc -n cicd

# Ver espacio disponible en Minikube
minikube ssh "df -h"
```

---

## 📚 Recursos

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [SonarQube Documentation](https://docs.sonarqube.org/)
- [Jenkins Kubernetes Plugin](https://plugins.jenkins.io/kubernetes/)
- [Helm Jenkins Chart](https://github.com/jenkinsci/helm-charts)
- [Helm SonarQube Chart](https://github.com/SonarSource/helm-chart-sonarqube)
