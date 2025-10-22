# Configuraciones Manuales Requeridas

Este archivo lista todas las configuraciones externas que debes realizar manualmente antes de ejecutar los despliegues.

## 1. Configuracion de Cuenta AWS

### Crear cuenta AWS (Free Tier)
1. Ir a https://aws.amazon.com/free/
2. Crear cuenta con tarjeta de credito (no se cobrara si te mantienes en free tier)
3. Verificar correo electronico

### Configurar AWS CLI
```bash
# Instalar AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configurar credenciales
aws configure
# AWS Access Key ID: [TU_ACCESS_KEY]
# AWS Secret Access Key: [TU_SECRET_KEY]
# Default region: us-east-1
# Default output format: json
```

### Crear usuario IAM con permisos necesarios
1. Ir a IAM Console
2. Crear usuario: "ecommerce-deployer"
3. Adjuntar politicas:
   - AmazonEKSClusterPolicy
   - AmazonEKSWorkerNodePolicy
   - AmazonEC2ContainerRegistryFullAccess
   - AmazonEKS_CNI_Policy
4. Crear Access Key y guardar credenciales

## 2. Instalacion de Jenkins

### Opcion A: Jenkins en Docker (Recomendado para desarrollo)
```bash
docker run -d -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --name jenkins \
  jenkins/jenkins:lts
```

### Opcion B: Jenkins nativo
```bash
# Ubuntu/Debian
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update
sudo apt-get install jenkins
```

### Configurar Jenkins
1. Abrir http://localhost:8080
2. Obtener password inicial: `docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword`
3. Instalar plugins recomendados
4. Instalar plugins adicionales:
   - Docker Pipeline
   - Kubernetes CLI
   - Pipeline Utility Steps
   - Blue Ocean (opcional)

### Configurar credenciales en Jenkins
1. Ir a "Manage Jenkins" > "Credentials"
2. Agregar credenciales:
   - Docker Hub (username/password)
   - AWS Credentials (AWS Access Key + Secret)
   - Kubernetes Config (archivo kubeconfig)

## 3. Configuracion de Docker Hub

### Crear cuenta
1. Ir a https://hub.docker.com/
2. Crear cuenta gratuita

### Crear repositorios para cada microservicio
```
tu-usuario/user-service
tu-usuario/product-service
tu-usuario/order-service
tu-usuario/payment-service
tu-usuario/shipping-service
tu-usuario/favourite-service
```

### Login en Docker CLI
```bash
docker login
# Username: [TU_USUARIO]
# Password: [TU_PASSWORD]
```

### Crear token de acceso (opcional pero recomendado)
1. Account Settings > Security > New Access Token
2. Guardar token para uso en Jenkins

## 4. Instalacion de Kubernetes Tools

### kubectl
```bash
# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client
```

### Minikube (para pruebas locales)
```bash
# Linux
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
minikube start --cpus=4 --memory=8192
```

### eksctl (para AWS EKS)
```bash
# Linux
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version
```

### Helm (opcional, para gestionar charts)
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

## 5. Configuracion de Variables de Entorno

### Crear archivo .env en la raiz del proyecto
```bash
# Docker Hub
DOCKER_USERNAME=tu-usuario
DOCKER_PASSWORD=tu-password-o-token

# AWS
AWS_ACCOUNT_ID=123456789012
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=tu-access-key
AWS_SECRET_ACCESS_KEY=tu-secret-key

# EKS
EKS_CLUSTER_NAME=ecommerce-cluster
EKS_NODE_TYPE=t3.medium
EKS_NODES_MIN=1
EKS_NODES_MAX=3

# Jenkins
JENKINS_URL=http://localhost:8080

# Aplicacion
SPRING_PROFILES_ACTIVE=prod
EUREKA_SERVER_URL=http://service-discovery:8761/eureka
```

### IMPORTANTE: Agregar .env al .gitignore
```bash
echo ".env" >> .gitignore
```

## 6. Secretos de Kubernetes

### Crear namespace
```bash
kubectl create namespace dev
kubectl create namespace stage
kubectl create namespace prod
```

### Crear secretos para Docker Registry
```bash
kubectl create secret docker-registry dockerhub-secret \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=tu-usuario \
  --docker-password=tu-password \
  --docker-email=tu-email@example.com \
  -n dev

kubectl create secret docker-registry dockerhub-secret \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=tu-usuario \
  --docker-password=tu-password \
  --docker-email=tu-email@example.com \
  -n stage

kubectl create secret docker-registry dockerhub-secret \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=tu-usuario \
  --docker-password=tu-password \
  --docker-email=tu-email@example.com \
  -n prod
```

### Crear secretos para base de datos (si usas RDS)
```bash
kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password=tu-password-seguro \
  -n prod
```

## 7. Configuracion de AWS EKS

### Crear cluster (esto puede tardar 15-20 minutos)
```bash
eksctl create cluster \
  --name ecommerce-cluster \
  --region us-east-1 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 1 \
  --nodes-max 3 \
  --managed
```

### Configurar kubectl para usar EKS
```bash
aws eks update-kubeconfig --region us-east-1 --name ecommerce-cluster
```

### Verificar conexion
```bash
kubectl get nodes
kubectl get namespaces
```

### Instalar AWS Load Balancer Controller (para Ingress)
```bash
eksctl utils associate-iam-oidc-provider --region=us-east-1 --cluster=ecommerce-cluster --approve

curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.7/docs/install/iam_policy.json

aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

eksctl create iamserviceaccount \
  --cluster=ecommerce-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::AWS_ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=ecommerce-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

## 8. Instalacion de Locust (para pruebas de rendimiento)

```bash
pip3 install locust
```

### Verificar instalacion
```bash
locust --version
```

## 9. Herramientas de Monitoreo (Opcional)

### Instalar Prometheus y Grafana en Kubernetes
```bash
kubectl create namespace monitoring

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring
```

### Acceder a Grafana
```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Usuario: admin
# Password: prom-operator
```

## 10. Verificacion Final

### Checklist de configuracion
- [ ] AWS CLI instalado y configurado
- [ ] Usuario IAM creado con permisos
- [ ] Jenkins instalado y accesible
- [ ] Plugins de Jenkins instalados
- [ ] Credenciales configuradas en Jenkins
- [ ] Docker Hub cuenta creada
- [ ] Repositorios creados en Docker Hub
- [ ] Docker login exitoso
- [ ] kubectl instalado
- [ ] Minikube instalado y funcionando
- [ ] eksctl instalado
- [ ] Cluster EKS creado
- [ ] kubectl configurado para EKS
- [ ] Namespaces creados en Kubernetes
- [ ] Secretos de Docker Registry creados
- [ ] Archivo .env creado (y en .gitignore)
- [ ] Locust instalado

### Comandos de verificacion
```bash
# AWS
aws sts get-caller-identity

# Docker
docker version
docker ps

# Kubernetes
kubectl version --client
kubectl get nodes
kubectl get namespaces

# Minikube
minikube status

# EKS
eksctl get cluster

# Locust
locust --version

# Jenkins
curl http://localhost:8080
```

## 11. Costos Estimados AWS (Free Tier)

### Servicios gratuitos (primer ano)
- EC2: 750 horas/mes de t3.micro
- ELB: 750 horas/mes
- EBS: 30 GB
- S3: 5 GB

### Servicios con costos potenciales
- EKS Control Plane: $0.10/hora ($73/mes) - NO INCLUIDO EN FREE TIER
- t3.medium nodes: Puede exceder free tier
- Data transfer: Primeros 100 GB/mes gratis

### Recomendacion para minimizar costos
1. Usar t3.micro en lugar de t3.medium (mas lento pero gratis)
2. Detener cluster cuando no se use: `eksctl delete cluster --name ecommerce-cluster`
3. Usar Minikube para desarrollo local
4. Monitorear uso en AWS Cost Explorer

## 12. Notas Importantes

- Mantener credenciales seguras y nunca commitearlas al repositorio
- Revisar costos de AWS regularmente
- Destruir recursos de AWS cuando no se usen
- Hacer backup de configuraciones importantes
- Documentar cualquier cambio en este archivo

## 13. Troubleshooting Comun

### Jenkins no puede conectarse a Docker
```bash
# Dar permisos al usuario jenkins
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### kubectl no puede conectarse a Minikube
```bash
minikube delete
minikube start --cpus=4 --memory=8192
```

### EKS nodes no se inician
```bash
# Verificar quotas de EC2 en tu region
aws service-quotas list-service-quotas --service-code ec2

# Verificar IAM roles
eksctl utils update-cluster-logging --enable-types all --region=us-east-1 --cluster=ecommerce-cluster
```

### Docker push falla
```bash
# Re-autenticar
docker logout
docker login
```
