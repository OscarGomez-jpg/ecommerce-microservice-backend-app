# 🛠️ Comandos Esenciales: Minikube y Kubectl

Guía de referencia rápida para gestionar Minikube y Kubernetes.

---

## 📦 Minikube - Gestión del Cluster

### Inicio y Detención

```bash
# Iniciar Minikube
minikube start

# Iniciar con recursos específicos
minikube start --memory=8192 --cpus=4

# Iniciar con driver específico
minikube start --driver=docker
minikube start --driver=kvm2

# Detener Minikube (mantiene estado)
minikube stop

# Eliminar cluster completamente
minikube delete

# Eliminar y recrear
minikube delete && minikube start --memory=10240 --cpus=4
```

### Información y Estado

```bash
# Ver estado de Minikube
minikube status

# Ver IP de Minikube
minikube ip

# Ver versión
minikube version

# Ver configuración
minikube config view

# Ver perfil activo
minikube profile list
```

### Configuración

```bash
# Configurar memoria (aplica en siguiente start)
minikube config set memory 8192

# Configurar CPUs
minikube config set cpus 4

# Configurar driver por defecto
minikube config set driver docker

# Ver configuración
minikube config view
```

### Addons

```bash
# Listar addons disponibles
minikube addons list

# Habilitar addon
minikube addons enable metrics-server
minikube addons enable dashboard
minikube addons enable ingress

# Deshabilitar addon
minikube addons disable dashboard

# Abrir dashboard
minikube dashboard
```

### Docker en Minikube

```bash
# Configurar shell para usar Docker de Minikube
eval $(minikube docker-env)

# Volver a Docker local
eval $(minikube docker-env -u)

# Ver variables de entorno Docker
minikube docker-env

# SSH a Minikube
minikube ssh

# Dentro de SSH, ver imágenes Docker
minikube ssh "docker images"

# Ejecutar comando Docker
minikube ssh "docker ps"
```

### Servicios y Acceso

```bash
# Listar servicios con URLs
minikube service list

# Abrir servicio en navegador
minikube service <SERVICE_NAME> -n <NAMESPACE>

# Ejemplo
minikube service jenkins -n cicd

# Obtener URL de servicio
minikube service <SERVICE_NAME> --url -n <NAMESPACE>
```

### Troubleshooting Minikube

```bash
# Ver logs de Minikube
minikube logs

# Ver logs últimas 50 líneas
minikube logs --length=50

# Ver estado detallado
minikube status -o json

# SSH para debugging
minikube ssh

# Ver espacio en disco
minikube ssh "df -h"

# Ver recursos del sistema
minikube ssh "free -h"

# Pausar cluster (libera recursos)
minikube pause

# Reanudar cluster
minikube unpause

# Limpiar imágenes no usadas
minikube ssh "docker system prune -a"
```

---

## ☸️ Kubectl - Gestión de Recursos

### Contexto y Configuración

```bash
# Ver contexto actual
kubectl config current-context

# Listar todos los contextos
kubectl config get-contexts

# Cambiar contexto
kubectl config use-context minikube

# Ver configuración completa
kubectl config view

# Setear namespace por defecto
kubectl config set-context --current --namespace=ecommerce
```

### Información del Cluster

```bash
# Ver información del cluster
kubectl cluster-info

# Ver nodos
kubectl get nodes

# Ver nodos con más detalles
kubectl get nodes -o wide

# Describir nodo
kubectl describe node minikube

# Ver versión de kubectl y server
kubectl version

# Ver recursos disponibles
kubectl api-resources
```

---

## 📋 Gestión de Recursos

### Namespaces

```bash
# Listar namespaces
kubectl get namespaces
kubectl get ns

# Crear namespace
kubectl create namespace ecommerce

# Describir namespace
kubectl describe namespace ecommerce

# Eliminar namespace (¡cuidado!)
kubectl delete namespace ecommerce

# Ver recursos en namespace
kubectl get all -n ecommerce
```

### Pods

```bash
# Listar pods
kubectl get pods
kubectl get pods -n ecommerce

# Listar todos los pods de todos los namespaces
kubectl get pods --all-namespaces
kubectl get pods -A

# Ver pods con más información
kubectl get pods -o wide

# Ver pods con labels
kubectl get pods --show-labels

# Filtrar por label
kubectl get pods -l app=user-service
kubectl get pods -l app=user-service -n ecommerce

# Describir pod
kubectl describe pod <POD_NAME> -n ecommerce

# Ver logs de pod
kubectl logs <POD_NAME> -n ecommerce

# Ver logs en tiempo real (follow)
kubectl logs -f <POD_NAME> -n ecommerce

# Ver logs de contenedor específico
kubectl logs <POD_NAME> -c <CONTAINER_NAME> -n ecommerce

# Ver logs de todos los pods con label
kubectl logs -l app=user-service -n ecommerce

# Ver logs últimas 100 líneas
kubectl logs <POD_NAME> --tail=100 -n ecommerce

# Ver logs con timestamps
kubectl logs <POD_NAME> --timestamps -n ecommerce

# Ejecutar comando en pod
kubectl exec <POD_NAME> -n ecommerce -- ls /app

# Entrar a shell de pod
kubectl exec -it <POD_NAME> -n ecommerce -- /bin/sh
kubectl exec -it <POD_NAME> -n ecommerce -- /bin/bash

# Port forward de pod a localhost
kubectl port-forward <POD_NAME> 8080:8080 -n ecommerce

# Copiar archivos desde/hacia pod
kubectl cp <POD_NAME>:/path/to/file ./local-file -n ecommerce
kubectl cp ./local-file <POD_NAME>:/path/to/file -n ecommerce

# Eliminar pod
kubectl delete pod <POD_NAME> -n ecommerce
```

### Deployments

```bash
# Listar deployments
kubectl get deployments
kubectl get deploy -n ecommerce

# Ver deployments con detalles
kubectl get deployments -o wide -n ecommerce

# Describir deployment
kubectl describe deployment user-service -n ecommerce

# Escalar deployment
kubectl scale deployment user-service --replicas=3 -n ecommerce

# Escalar a 0 (detener sin eliminar)
kubectl scale deployment user-service --replicas=0 -n ecommerce

# Ver estado de rollout
kubectl rollout status deployment/user-service -n ecommerce

# Ver historial de rollout
kubectl rollout history deployment/user-service -n ecommerce

# Hacer rollback
kubectl rollout undo deployment/user-service -n ecommerce

# Rollback a revisión específica
kubectl rollout undo deployment/user-service --to-revision=2 -n ecommerce

# Restart deployment (recrear pods)
kubectl rollout restart deployment/user-service -n ecommerce

# Pausar rollout
kubectl rollout pause deployment/user-service -n ecommerce

# Reanudar rollout
kubectl rollout resume deployment/user-service -n ecommerce

# Actualizar imagen
kubectl set image deployment/user-service user-service=user-service:v2 -n ecommerce

# Editar deployment en vivo
kubectl edit deployment user-service -n ecommerce

# Eliminar deployment
kubectl delete deployment user-service -n ecommerce
```

### Services

```bash
# Listar servicios
kubectl get services
kubectl get svc -n ecommerce

# Ver servicios con más detalles
kubectl get svc -o wide -n ecommerce

# Describir servicio
kubectl describe service user-service -n ecommerce

# Ver endpoints del servicio
kubectl get endpoints user-service -n ecommerce

# Eliminar servicio
kubectl delete service user-service -n ecommerce
```

### ConfigMaps y Secrets

```bash
# Listar ConfigMaps
kubectl get configmaps -n ecommerce
kubectl get cm -n ecommerce

# Ver contenido de ConfigMap
kubectl describe configmap <NAME> -n ecommerce
kubectl get configmap <NAME> -o yaml -n ecommerce

# Crear ConfigMap desde literal
kubectl create configmap my-config --from-literal=key1=value1 -n ecommerce

# Crear ConfigMap desde archivo
kubectl create configmap my-config --from-file=config.properties -n ecommerce

# Listar Secrets
kubectl get secrets -n ecommerce

# Ver Secret (codificado en base64)
kubectl get secret <NAME> -o yaml -n ecommerce

# Decodificar Secret
kubectl get secret <NAME> -o jsonpath='{.data.password}' -n ecommerce | base64 -d

# Crear Secret
kubectl create secret generic my-secret --from-literal=password=mysecret -n ecommerce
```

### PersistentVolumes y PersistentVolumeClaims

```bash
# Listar PersistentVolumes (cluster-wide)
kubectl get pv

# Listar PersistentVolumeClaims
kubectl get pvc -n ecommerce

# Describir PVC
kubectl describe pvc jenkins -n cicd

# Ver espacio usado
kubectl get pvc -n cicd -o custom-columns=NAME:.metadata.name,CAPACITY:.spec.resources.requests.storage,USED:.status.capacity.storage
```

---

## 🔍 Debugging y Troubleshooting

### Información de Recursos

```bash
# Ver todos los recursos de un namespace
kubectl get all -n ecommerce

# Ver eventos recientes
kubectl get events -n ecommerce

# Ver eventos ordenados por tiempo
kubectl get events --sort-by='.lastTimestamp' -n ecommerce

# Ver eventos de los últimos 5 minutos
kubectl get events --sort-by='.lastTimestamp' -n ecommerce --field-selector=involvedObject.kind=Pod

# Describe completo (pods, services, deployments)
kubectl describe all -n ecommerce
```

### Recursos y Métricas

```bash
# Ver uso de recursos de nodos
kubectl top nodes

# Ver uso de recursos de pods
kubectl top pods -n ecommerce

# Ver pods que más consumen memoria
kubectl top pods -n ecommerce --sort-by=memory

# Ver pods que más consumen CPU
kubectl top pods -n ecommerce --sort-by=cpu

# Ver contenedores en pods
kubectl top pods -n ecommerce --containers
```

### Estados y Condiciones

```bash
# Ver pods que no están Running
kubectl get pods -n ecommerce --field-selector=status.phase!=Running

# Ver pods con problemas
kubectl get pods -n ecommerce | grep -v "Running\|Completed"

# Esperar a que pod esté ready
kubectl wait --for=condition=ready pod -l app=user-service -n ecommerce --timeout=300s

# Ver pods con restart count alto
kubectl get pods -n ecommerce --sort-by='.status.containerStatuses[0].restartCount'
```

### Logs Avanzados

```bash
# Ver logs de múltiples pods
kubectl logs -l app=user-service -n ecommerce --all-containers=true

# Ver logs desde hace 1 hora
kubectl logs <POD_NAME> --since=1h -n ecommerce

# Ver logs entre timestamps
kubectl logs <POD_NAME> --since-time='2025-10-28T10:00:00Z' -n ecommerce

# Ver logs de pod anterior (después de crash)
kubectl logs <POD_NAME> --previous -n ecommerce

# Stream logs de múltiples pods
kubectl logs -l app=user-service -f -n ecommerce
```

---

## 📝 Aplicar Manifiestos

### Apply y Create

```bash
# Aplicar archivo YAML
kubectl apply -f deployment.yaml

# Aplicar directorio completo
kubectl apply -f k8s-minikube/

# Aplicar desde URL
kubectl apply -f https://example.com/manifest.yaml

# Crear recurso (falla si existe)
kubectl create -f deployment.yaml

# Dry-run (ver qué haría sin aplicar)
kubectl apply -f deployment.yaml --dry-run=client

# Dry-run server (validación en servidor)
kubectl apply -f deployment.yaml --dry-run=server

# Ver diff antes de aplicar
kubectl diff -f deployment.yaml
```

### Delete

```bash
# Eliminar por archivo
kubectl delete -f deployment.yaml

# Eliminar directorio completo
kubectl delete -f k8s-minikube/

# Eliminar por tipo y nombre
kubectl delete deployment user-service -n ecommerce

# Eliminar por label
kubectl delete pods -l app=user-service -n ecommerce

# Eliminar todos los pods de namespace
kubectl delete pods --all -n ecommerce

# Forzar eliminación
kubectl delete pod <POD_NAME> --force --grace-period=0 -n ecommerce
```

### Get YAML/JSON

```bash
# Ver recurso en YAML
kubectl get deployment user-service -o yaml -n ecommerce

# Ver recurso en JSON
kubectl get deployment user-service -o json -n ecommerce

# Exportar recurso actual
kubectl get deployment user-service -o yaml -n ecommerce > deployment-backup.yaml

# Ver campos específicos con jsonpath
kubectl get pods -o jsonpath='{.items[*].metadata.name}' -n ecommerce

# Ver custom columns
kubectl get pods -o custom-columns=NAME:.metadata.name,STATUS:.status.phase -n ecommerce
```

---

## 🔐 RBAC - Permisos

```bash
# Ver ServiceAccounts
kubectl get serviceaccounts -n cicd
kubectl get sa -n cicd

# Ver Roles y ClusterRoles
kubectl get roles -n cicd
kubectl get clusterroles

# Ver RoleBindings y ClusterRoleBindings
kubectl get rolebindings -n cicd
kubectl get clusterrolebindings

# Describir role
kubectl describe clusterrole jenkins-deploy

# Ver permisos de ServiceAccount
kubectl auth can-i list pods --as=system:serviceaccount:cicd:jenkins -n ecommerce

# Ver todos los permisos que tengo
kubectl auth can-i --list
```

---

## 📊 Helm - Package Manager

```bash
# Agregar repositorio
helm repo add jenkins https://charts.jenkins.io
helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube

# Actualizar repositorios
helm repo update

# Listar repos
helm repo list

# Buscar charts
helm search repo jenkins

# Instalar chart
helm install jenkins jenkins/jenkins -n cicd -f jenkins-values.yaml

# Actualizar release
helm upgrade jenkins jenkins/jenkins -n cicd -f jenkins-values.yaml

# Desinstalar
helm uninstall jenkins -n cicd

# Listar releases
helm list -n cicd
helm list --all-namespaces

# Ver valores de release
helm get values jenkins -n cicd

# Ver manifest completo
helm get manifest jenkins -n cicd

# Ver historial
helm history jenkins -n cicd

# Rollback
helm rollback jenkins 1 -n cicd
```

---

## 🚀 Comandos de Uso Frecuente

### Verificación Rápida del Estado

```bash
# Script de verificación completa
alias k8s-status='
echo "=== NODES ===" && kubectl get nodes &&
echo -e "\n=== NAMESPACES ===" && kubectl get ns &&
echo -e "\n=== PODS (ecommerce) ===" && kubectl get pods -n ecommerce &&
echo -e "\n=== PODS (cicd) ===" && kubectl get pods -n cicd &&
echo -e "\n=== SERVICES (ecommerce) ===" && kubectl get svc -n ecommerce &&
echo -e "\n=== DEPLOYMENTS (ecommerce) ===" && kubectl get deployments -n ecommerce
'

# Ejecutar
k8s-status
```

### Ver Logs de Todos los Servicios

```bash
# Ver últimas 10 líneas de cada servicio
for service in service-discovery api-gateway user-service product-service order-service; do
    echo "=== $service ==="
    kubectl logs -l app=$service -n ecommerce --tail=10
    echo ""
done
```

### Restart de Todos los Servicios

```bash
# Restart secuencial
kubectl rollout restart deployment/service-discovery -n ecommerce
sleep 30
kubectl rollout restart deployment/api-gateway -n ecommerce
kubectl rollout restart deployment/user-service -n ecommerce
kubectl rollout restart deployment/product-service -n ecommerce
kubectl rollout restart deployment/order-service -n ecommerce
```

### Limpiar Recursos

```bash
# Eliminar todos los pods completados
kubectl delete pods --field-selector=status.phase=Succeeded -n ecommerce

# Eliminar todos los pods con error
kubectl delete pods --field-selector=status.phase=Failed -n ecommerce

# Limpiar recursos no utilizados
kubectl delete $(kubectl get pods -n ecommerce -o go-template --template '{{range .items}}{{if not .status.containerStatuses}}{{.metadata.name}} {{end}}{{end}}')
```

---

## 💡 Tips y Trucos

### Aliases Útiles

```bash
# Agregar a ~/.bashrc o ~/.zshrc
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deployments'
alias kga='kubectl get all'
alias kaf='kubectl apply -f'
alias kdel='kubectl delete'
alias klog='kubectl logs'
alias kexec='kubectl exec -it'
alias kdesc='kubectl describe'
alias kns='kubectl config set-context --current --namespace'

# Autocompletado
source <(kubectl completion bash)
# o para zsh
source <(kubectl completion zsh)
```

### Watch Mode

```bash
# Observar cambios en tiempo real
watch kubectl get pods -n ecommerce

# O usar -w de kubectl
kubectl get pods -n ecommerce -w

# Ver eventos en tiempo real
kubectl get events -n ecommerce -w
```

### JSON Queries con jq

```bash
# Instalar jq si no lo tienes
sudo apt install jq

# Ejemplos
kubectl get pods -n ecommerce -o json | jq '.items[].metadata.name'
kubectl get pods -n ecommerce -o json | jq '.items[] | {name: .metadata.name, status: .status.phase}'
kubectl get nodes -o json | jq '.items[].status.addresses'
```

### Shell Functions Útiles

```bash
# Agregar a ~/.bashrc
# Port-forward rápido
kpf() {
    kubectl port-forward "$(kubectl get pod -l app=$1 -o jsonpath='{.items[0].metadata.name}' -n $2)" $3:$4 -n $2
}
# Uso: kpf user-service ecommerce 8080 8700

# Logs de servicio
klogs() {
    kubectl logs -f -l app=$1 -n $2 --all-containers=true
}
# Uso: klogs user-service ecommerce

# Shell de servicio
ksh() {
    kubectl exec -it "$(kubectl get pod -l app=$1 -o jsonpath='{.items[0].metadata.name}' -n $2)" -n $2 -- /bin/sh
}
# Uso: ksh user-service ecommerce
```

---

## 🆘 Comandos de Emergencia

### Cluster No Responde

```bash
# Reiniciar Minikube
minikube stop && minikube start

# Si falla, eliminar y recrear
minikube delete && minikube start --memory=10240 --cpus=4

# Limpiar cache de kubectl
rm -rf ~/.kube/cache
```

### Pod Stuck en Terminating

```bash
# Forzar eliminación
kubectl delete pod <POD_NAME> --force --grace-period=0 -n ecommerce

# Si sigue stuck, eliminar finalizers
kubectl patch pod <POD_NAME> -p '{"metadata":{"finalizers":null}}' -n ecommerce
```

### Deployment Stuck

```bash
# Ver estado de rollout
kubectl rollout status deployment/<NAME> -n ecommerce

# Cancelar rollout actual
kubectl rollout undo deployment/<NAME> -n ecommerce

# Eliminar y recrear
kubectl delete deployment <NAME> -n ecommerce
kubectl apply -f deployment.yaml
```

### Namespace Stuck en Terminating

```bash
# Ver qué recursos quedan
kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -n <NAMESPACE>

# Forzar eliminación (usar con cuidado)
kubectl get namespace <NAMESPACE> -o json | jq '.spec.finalizers=[]' | kubectl replace --raw "/api/v1/namespaces/<NAMESPACE>/finalize" -f -
```

---

## 📚 Referencias

- [Kubectl Cheat Sheet Oficial](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [Kubectl Documentation](https://kubectl.docs.kubernetes.io/)
- [Helm Documentation](https://helm.sh/docs/)

---

**Tip:** Usa `kubectl explain <RESOURCE>` para ver documentación de cualquier recurso.

Ejemplo:
```bash
kubectl explain pod
kubectl explain deployment.spec
kubectl explain service.spec.type
```
