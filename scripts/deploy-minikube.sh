#!/bin/bash

set -e

echo "=========================================="
echo "Despliegue Completo en Minikube"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Verificar que Minikube está corriendo
echo -e "${YELLOW}1. Verificando Minikube...${NC}"
if ! minikube status | grep -q "Running"; then
    echo "Minikube no está corriendo. Iniciando..."
    minikube start --cpus=4 --memory=8192 --disk-size=20g --driver=docker
fi
echo -e "${GREEN}✓ Minikube corriendo${NC}"
echo ""

# Configurar Docker para usar Minikube
echo -e "${YELLOW}2. Configurando Docker para Minikube...${NC}"
eval $(minikube docker-env)
echo -e "${GREEN}✓ Docker configurado${NC}"
echo ""

# Compilar servicios
echo -e "${YELLOW}3. Compilando servicios con Java 11...${NC}"
if [ ! -f "user-service/target/user-service-v0.1.0.jar" ]; then
    echo "Compilando todos los servicios..."
    ./scripts/build-with-docker.sh
else
    echo "Servicios ya compilados (omitiendo compilación)"
fi
echo -e "${GREEN}✓ Servicios compilados${NC}"
echo ""

# Construir imágenes Docker en Minikube
echo -e "${YELLOW}4. Construyendo imágenes Docker en Minikube...${NC}"

echo "  - service-discovery..."
docker build -t service-discovery:local -f service-discovery/Dockerfile service-discovery/ > /dev/null 2>&1

echo "  - api-gateway..."
docker build -t api-gateway:local -f api-gateway/Dockerfile api-gateway/ > /dev/null 2>&1

echo "  - user-service..."
docker build -t user-service:local -f user-service/Dockerfile user-service/ > /dev/null 2>&1

echo "  - product-service..."
docker build -t product-service:local -f product-service/Dockerfile product-service/ > /dev/null 2>&1

echo "  - order-service..."
docker build -t order-service:local -f order-service/Dockerfile order-service/ > /dev/null 2>&1

echo -e "${GREEN}✓ Imágenes Docker construidas${NC}"
echo ""

# Verificar imágenes
echo -e "${YELLOW}5. Verificando imágenes construidas...${NC}"
docker images | grep local | awk '{print "  - " $1 ":" $2 " (" $7 " " $8 ")"}'
echo ""

# Crear namespace
echo -e "${YELLOW}6. Creando namespace 'ecommerce'...${NC}"
kubectl apply -f k8s-minikube/00-namespace.yaml
echo -e "${GREEN}✓ Namespace creado${NC}"
echo ""

# Desplegar servicios
echo -e "${YELLOW}7. Desplegando microservicios...${NC}"

echo "  - Zipkin (tracing)..."
kubectl apply -f k8s-minikube/01-zipkin.yaml

echo "  - Service Discovery (Eureka)..."
kubectl apply -f k8s-minikube/02-service-discovery.yaml

echo "  - API Gateway..."
kubectl apply -f k8s-minikube/03-api-gateway.yaml

echo "  - User Service..."
kubectl apply -f k8s-minikube/04-user-service.yaml

echo "  - Product Service..."
kubectl apply -f k8s-minikube/05-product-service.yaml

echo "  - Order Service..."
kubectl apply -f k8s-minikube/06-order-service.yaml

echo -e "${GREEN}✓ Microservicios desplegados${NC}"
echo ""

# Esperar a que los pods estén listos
echo -e "${YELLOW}8. Esperando a que los pods estén listos...${NC}"
echo "   (Esto puede tomar 2-3 minutos)"
echo ""

# Esperar Zipkin
echo -n "  - Zipkin... "
kubectl wait --for=condition=ready pod -l app=zipkin -n ecommerce --timeout=120s > /dev/null 2>&1 && echo -e "${GREEN}✓${NC}" || echo -e "${YELLOW}⏳${NC}"

# Esperar Eureka
echo -n "  - Eureka... "
kubectl wait --for=condition=ready pod -l app=service-discovery -n ecommerce --timeout=180s > /dev/null 2>&1 && echo -e "${GREEN}✓${NC}" || echo -e "${YELLOW}⏳${NC}"

# Esperar API Gateway
echo -n "  - API Gateway... "
kubectl wait --for=condition=ready pod -l app=api-gateway -n ecommerce --timeout=180s > /dev/null 2>&1 && echo -e "${GREEN}✓${NC}" || echo -e "${YELLOW}⏳${NC}"

# Esperar User Service
echo -n "  - User Service... "
kubectl wait --for=condition=ready pod -l app=user-service -n ecommerce --timeout=180s > /dev/null 2>&1 && echo -e "${GREEN}✓${NC}" || echo -e "${YELLOW}⏳${NC}"

# Esperar Product Service
echo -n "  - Product Service... "
kubectl wait --for=condition=ready pod -l app=product-service -n ecommerce --timeout=180s > /dev/null 2>&1 && echo -e "${GREEN}✓${NC}" || echo -e "${YELLOW}⏳${NC}"

# Esperar Order Service
echo -n "  - Order Service... "
kubectl wait --for=condition=ready pod -l app=order-service -n ecommerce --timeout=180s > /dev/null 2>&1 && echo -e "${GREEN}✓${NC}" || echo -e "${YELLOW}⏳${NC}"

echo ""

# Mostrar estado final
echo "=========================================="
echo -e "${GREEN}Deployment Completo!${NC}"
echo "=========================================="
echo ""

MINIKUBE_IP=$(minikube ip)

echo -e "${BLUE}Estado de los Pods:${NC}"
kubectl get pods -n ecommerce
echo ""

echo -e "${BLUE}Estado de los Servicios:${NC}"
kubectl get svc -n ecommerce
echo ""

echo "=========================================="
echo -e "${GREEN}URLs de Acceso:${NC}"
echo "=========================================="
echo ""
echo "  Minikube IP: $MINIKUBE_IP"
echo ""
echo "  Eureka Dashboard:"
echo "    http://$MINIKUBE_IP:30761"
echo ""
echo "  Zipkin UI:"
echo "    http://$MINIKUBE_IP:30411"
echo ""
echo "  API Gateway:"
echo "    http://$MINIKUBE_IP:30080"
echo ""

echo "=========================================="
echo "Comandos Útiles:"
echo "=========================================="
echo ""
echo "  Ver logs de un servicio:"
echo "    kubectl logs -n ecommerce -l app=user-service -f"
echo ""
echo "  Ver estado de pods:"
echo "    kubectl get pods -n ecommerce"
echo ""
echo "  Ver uso de recursos:"
echo "    kubectl top pods -n ecommerce"
echo ""
echo "  Port-forward para acceso directo:"
echo "    kubectl port-forward -n ecommerce svc/user-service 8700:8700"
echo ""
echo "  Verificar microservicios:"
echo "    ./scripts/verify-microservices-minikube.sh"
echo ""
echo "  Abrir dashboard de Kubernetes:"
echo "    minikube dashboard"
echo ""

echo "=========================================="
echo -e "${GREEN}¡Todo listo! Abre Eureka para verificar los servicios registrados.${NC}"
echo "=========================================="
