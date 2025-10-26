#!/bin/bash

#############################################################
# AWS K3S Deployment Script - Temporal (72 horas)
#
# Costo estimado: $1.66 USD por 72 horas
# Instancia: t2.small (1 vCPU, 2 GB RAM)
#
# IMPORTANTE: Este script crea recursos que CUESTAN DINERO
# Ejecuta aws-k3s-destroy.sh cuando termines para evitar cargos
#############################################################

set -e

echo "=============================================="
echo "AWS K3S Deployment - Microservicios E-Commerce"
echo "=============================================="
echo ""
echo "ADVERTENCIA: Este script creara recursos en AWS que generan costos"
echo "Costo estimado: \$1.66 USD por 72 horas"
echo ""
read -p "Presiona ENTER para continuar o CTRL+C para cancelar..."

# Variables de configuración
INSTANCE_NAME="ecommerce-k3s-cluster"
INSTANCE_TYPE="t2.small"
REGION="${AWS_REGION:-us-east-1}"
KEY_NAME="ecommerce-k3s-key-$(date +%s)"
SECURITY_GROUP_NAME="ecommerce-k3s-sg"

# Obtener la AMI más reciente de Ubuntu 22.04
echo ""
echo "[1/8] Obteniendo AMI de Ubuntu 22.04 en región $REGION..."
AMI_ID=$(aws ec2 describe-images \
    --region $REGION \
    --owners 099720109477 \
    --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" \
              "Name=state,Values=available" \
    --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
    --output text)

if [ -z "$AMI_ID" ]; then
    echo "Error: No se pudo encontrar AMI de Ubuntu"
    exit 1
fi
echo "   AMI seleccionada: $AMI_ID"

# Crear Security Group
echo ""
echo "[2/8] Creando Security Group..."
SG_ID=$(aws ec2 create-security-group \
    --region $REGION \
    --group-name $SECURITY_GROUP_NAME \
    --description "Security group for k3s microservices" \
    --output text --query 'GroupId')

echo "   Security Group creado: $SG_ID"

# Configurar reglas del Security Group
echo "   Configurando reglas de firewall..."
aws ec2 authorize-security-group-ingress --region $REGION --group-id $SG_ID --protocol tcp --port 22 --cidr 0.0.0.0/0 > /dev/null 2>&1 || true
aws ec2 authorize-security-group-ingress --region $REGION --group-id $SG_ID --protocol tcp --port 6443 --cidr 0.0.0.0/0 > /dev/null 2>&1 || true
aws ec2 authorize-security-group-ingress --region $REGION --group-id $SG_ID --protocol tcp --port 8080 --cidr 0.0.0.0/0 > /dev/null 2>&1 || true
aws ec2 authorize-security-group-ingress --region $REGION --group-id $SG_ID --protocol tcp --port 8761 --cidr 0.0.0.0/0 > /dev/null 2>&1 || true
aws ec2 authorize-security-group-ingress --region $REGION --group-id $SG_ID --protocol tcp --port 9411 --cidr 0.0.0.0/0 > /dev/null 2>&1 || true

# Crear Key Pair
echo ""
echo "[3/8] Creando Key Pair..."
mkdir -p ~/.ssh
aws ec2 create-key-pair \
    --region $REGION \
    --key-name $KEY_NAME \
    --query 'KeyMaterial' \
    --output text > ~/.ssh/${KEY_NAME}.pem

chmod 400 ~/.ssh/${KEY_NAME}.pem
echo "   Key guardada en: ~/.ssh/${KEY_NAME}.pem"

# Crear User Data para instalación automática
echo ""
echo "[4/8] Preparando script de instalación..."
cat > /tmp/k3s-userdata.sh << 'USERDATA_EOF'
#!/bin/bash
set -e

# Log everything
exec > >(tee /var/log/k3s-setup.log)
exec 2>&1

echo "===== Iniciando instalación de K3S ====="
date

# Actualizar sistema
apt-get update
apt-get install -y curl wget

# Instalar k3s
echo "Instalando k3s..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" sh -

# Esperar a que k3s esté listo
echo "Esperando a que k3s esté listo..."
sleep 30

# Configurar kubectl para ubuntu user
mkdir -p /home/ubuntu/.kube
cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
chown -R ubuntu:ubuntu /home/ubuntu/.kube
chmod 600 /home/ubuntu/.kube/config

# Exportar KUBECONFIG
echo 'export KUBECONFIG=/home/ubuntu/.kube/config' >> /home/ubuntu/.bashrc

echo "===== K3S instalado correctamente ====="
date
USERDATA_EOF

# Lanzar instancia EC2
echo ""
echo "[5/8] Lanzando instancia EC2 t2.small..."
INSTANCE_ID=$(aws ec2 run-instances \
    --region $REGION \
    --image-id $AMI_ID \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-group-ids $SG_ID \
    --user-data file:///tmp/k3s-userdata.sh \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME},{Key=Project,Value=ecommerce-microservices},{Key=AutoShutdown,Value=72h}]" \
    --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":20,"VolumeType":"gp3"}}]' \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "   Instancia creada: $INSTANCE_ID"

# Esperar a que la instancia esté running
echo ""
echo "[6/8] Esperando a que la instancia esté lista..."
aws ec2 wait instance-running --region $REGION --instance-ids $INSTANCE_ID

# Obtener IP pública
PUBLIC_IP=$(aws ec2 describe-instances \
    --region $REGION \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo "   Instancia corriendo en: $PUBLIC_IP"

# Guardar información para destrucción posterior
cat > ~/.aws-k3s-deployment.conf << EOF
INSTANCE_ID=$INSTANCE_ID
SECURITY_GROUP_ID=$SG_ID
KEY_NAME=$KEY_NAME
PUBLIC_IP=$PUBLIC_IP
REGION=$REGION
DEPLOYED_AT=$(date)
EOF

echo ""
echo "[7/8] Esperando instalación de k3s (esto toma ~2 minutos)..."
sleep 120

# Verificar que k3s está instalado
echo ""
echo "[8/8] Verificando instalación de k3s..."
MAX_RETRIES=10
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i ~/.ssh/${KEY_NAME}.pem ubuntu@${PUBLIC_IP} "sudo k3s kubectl get nodes" > /dev/null 2>&1; then
        echo "   k3s instalado y funcionando!"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    echo "   Intento $RETRY_COUNT/$MAX_RETRIES - Esperando 30 segundos..."
    sleep 30
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "   ADVERTENCIA: No se pudo verificar k3s. Puede necesitar más tiempo."
    echo "   Puedes verificar manualmente con: ssh -i ~/.ssh/${KEY_NAME}.pem ubuntu@${PUBLIC_IP}"
fi

# Crear archivo con manifiestos optimizados
echo ""
echo "Preparando manifiestos de Kubernetes optimizados para 2GB RAM..."

cat > /tmp/k3s-manifests.yaml << 'MANIFESTS_EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: ecommerce
---
apiVersion: v1
kind: Service
metadata:
  name: zipkin
  namespace: ecommerce
spec:
  type: ClusterIP
  ports:
  - port: 9411
    targetPort: 9411
  selector:
    app: zipkin
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: zipkin
  namespace: ecommerce
spec:
  replicas: 1
  selector:
    matchLabels:
      app: zipkin
  template:
    metadata:
      labels:
        app: zipkin
    spec:
      containers:
      - name: zipkin
        image: openzipkin/zipkin
        ports:
        - containerPort: 9411
        resources:
          requests:
            memory: "200Mi"
            cpu: "100m"
          limits:
            memory: "300Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: service-discovery
  namespace: ecommerce
spec:
  type: NodePort
  ports:
  - port: 8761
    targetPort: 8761
    nodePort: 30761
  selector:
    app: service-discovery
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: service-discovery
  namespace: ecommerce
spec:
  replicas: 1
  selector:
    matchLabels:
      app: service-discovery
  template:
    metadata:
      labels:
        app: service-discovery
    spec:
      containers:
      - name: service-discovery
        image: selimhorri/service-discovery-ecommerce-boot:0.1.0
        ports:
        - containerPort: 8761
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "dev"
        - name: JAVA_OPTS
          value: "-Xmx256m -Xms128m"
        resources:
          requests:
            memory: "300Mi"
            cpu: "100m"
          limits:
            memory: "400Mi"
            cpu: "300m"
---
apiVersion: v1
kind: Service
metadata:
  name: api-gateway
  namespace: ecommerce
spec:
  type: NodePort
  ports:
  - port: 8080
    targetPort: 8080
    nodePort: 30080
  selector:
    app: api-gateway
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
  namespace: ecommerce
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api-gateway
  template:
    metadata:
      labels:
        app: api-gateway
    spec:
      containers:
      - name: api-gateway
        image: selimhorri/api-gateway-ecommerce-boot:0.1.0
        ports:
        - containerPort: 8080
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "dev"
        - name: EUREKA_CLIENT_SERVICEURL_DEFAULTZONE
          value: "http://service-discovery:8761/eureka"
        - name: SPRING_ZIPKIN_BASE_URL
          value: "http://zipkin:9411/"
        - name: JAVA_OPTS
          value: "-Xmx256m -Xms128m"
        resources:
          requests:
            memory: "300Mi"
            cpu: "100m"
          limits:
            memory: "400Mi"
            cpu: "300m"
---
apiVersion: v1
kind: Service
metadata:
  name: user-service
  namespace: ecommerce
spec:
  type: ClusterIP
  ports:
  - port: 8700
    targetPort: 8700
  selector:
    app: user-service
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user-service
  namespace: ecommerce
spec:
  replicas: 1
  selector:
    matchLabels:
      app: user-service
  template:
    metadata:
      labels:
        app: user-service
    spec:
      containers:
      - name: user-service
        image: selimhorri/user-service-ecommerce-boot:0.1.0
        ports:
        - containerPort: 8700
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "dev"
        - name: EUREKA_CLIENT_SERVICEURL_DEFAULTZONE
          value: "http://service-discovery:8761/eureka"
        - name: SPRING_ZIPKIN_BASE_URL
          value: "http://zipkin:9411/"
        - name: JAVA_OPTS
          value: "-Xmx256m -Xms128m"
        resources:
          requests:
            memory: "250Mi"
            cpu: "100m"
          limits:
            memory: "350Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: product-service
  namespace: ecommerce
spec:
  type: ClusterIP
  ports:
  - port: 8500
    targetPort: 8500
  selector:
    app: product-service
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: product-service
  namespace: ecommerce
spec:
  replicas: 1
  selector:
    matchLabels:
      app: product-service
  template:
    metadata:
      labels:
        app: product-service
    spec:
      containers:
      - name: product-service
        image: selimhorri/product-service-ecommerce-boot:0.1.0
        ports:
        - containerPort: 8500
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "dev"
        - name: EUREKA_CLIENT_SERVICEURL_DEFAULTZONE
          value: "http://service-discovery:8761/eureka"
        - name: SPRING_ZIPKIN_BASE_URL
          value: "http://zipkin:9411/"
        - name: JAVA_OPTS
          value: "-Xmx256m -Xms128m"
        resources:
          requests:
            memory: "250Mi"
            cpu: "100m"
          limits:
            memory: "350Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: order-service
  namespace: ecommerce
spec:
  type: ClusterIP
  ports:
  - port: 8300
    targetPort: 8300
  selector:
    app: order-service
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: order-service
  namespace: ecommerce
spec:
  replicas: 1
  selector:
    matchLabels:
      app: order-service
  template:
    metadata:
      labels:
        app: order-service
    spec:
      containers:
      - name: order-service
        image: selimhorri/order-service-ecommerce-boot:0.1.0
        ports:
        - containerPort: 8300
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "dev"
        - name: EUREKA_CLIENT_SERVICEURL_DEFAULTZONE
          value: "http://service-discovery:8761/eureka"
        - name: SPRING_ZIPKIN_BASE_URL
          value: "http://zipkin:9411/"
        - name: JAVA_OPTS
          value: "-Xmx256m -Xms128m"
        resources:
          requests:
            memory: "250Mi"
            cpu: "100m"
          limits:
            memory: "350Mi"
            cpu: "200m"
MANIFESTS_EOF

# Copiar manifiestos al servidor
echo "Copiando manifiestos al servidor..."
scp -o StrictHostKeyChecking=no -i ~/.ssh/${KEY_NAME}.pem /tmp/k3s-manifests.yaml ubuntu@${PUBLIC_IP}:/home/ubuntu/

# Desplegar servicios
echo ""
echo "Desplegando microservicios en k3s..."
ssh -o StrictHostKeyChecking=no -i ~/.ssh/${KEY_NAME}.pem ubuntu@${PUBLIC_IP} << 'DEPLOY_EOF'
export KUBECONFIG=/home/ubuntu/.kube/config
sudo k3s kubectl apply -f /home/ubuntu/k3s-manifests.yaml

echo ""
echo "Esperando a que los pods estén ready..."
sudo k3s kubectl wait --for=condition=ready pod --all -n ecommerce --timeout=300s || true

echo ""
echo "Estado de los pods:"
sudo k3s kubectl get pods -n ecommerce
DEPLOY_EOF

echo ""
echo "=============================================="
echo "DEPLOYMENT COMPLETADO!"
echo "=============================================="
echo ""
echo "Información de acceso:"
echo "  IP Pública: $PUBLIC_IP"
echo "  SSH: ssh -i ~/.ssh/${KEY_NAME}.pem ubuntu@${PUBLIC_IP}"
echo ""
echo "Servicios disponibles:"
echo "  - Eureka Dashboard: http://${PUBLIC_IP}:30761"
echo "  - API Gateway: http://${PUBLIC_IP}:30080"
echo ""
echo "Comandos útiles:"
echo "  Ver pods: ssh -i ~/.ssh/${KEY_NAME}.pem ubuntu@${PUBLIC_IP} 'sudo k3s kubectl get pods -n ecommerce'"
echo "  Ver logs: ssh -i ~/.ssh/${KEY_NAME}.pem ubuntu@${PUBLIC_IP} 'sudo k3s kubectl logs -f <pod-name> -n ecommerce'"
echo ""
echo "IMPORTANTE:"
echo "  Este deployment cuesta ~\$0.023/hora (\$0.55/día)"
echo "  Para 72 horas: ~\$1.66 USD"
echo ""
echo "  Cuando termines, EJECUTA:"
echo "  ./scripts/aws-k3s-destroy.sh"
echo ""
echo "  Archivo de configuración guardado en:"
echo "  ~/.aws-k3s-deployment.conf"
echo "=============================================="
