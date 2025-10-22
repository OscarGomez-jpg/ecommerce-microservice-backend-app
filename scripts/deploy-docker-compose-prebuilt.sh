#!/bin/bash

set -e

echo "=========================================="
echo "Desplegando con Docker Compose"
echo "(usando JARs ya compilados)"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}ERROR: docker is not installed${NC}"
    exit 1
fi

# Check if JARs were built
echo -e "${YELLOW}Verificando que los JARs esten compilados...${NC}"
if [ ! -f "user-service/target/user-service-v0.1.0.jar" ]; then
    echo -e "${RED}ERROR: JARs no encontrados${NC}"
    echo ""
    echo "Primero debes compilar con:"
    echo "  ./scripts/build-with-docker.sh"
    echo ""
    exit 1
fi

echo -e "${GREEN}JARs encontrados!${NC}"
echo ""

# Build Docker images for all services
echo -e "${YELLOW}Construyendo imagenes Docker...${NC}"

services=("service-discovery" "cloud-config" "api-gateway" "proxy-client" "user-service" "product-service" "order-service" "payment-service" "shipping-service" "favourite-service")

for service in "${services[@]}"; do
    echo -e "${YELLOW}Building ${service}...${NC}"
    cd ${service}
    docker build -t selimhorri/${service}-ecommerce-boot:0.1.0 \
        --build-arg PROJECT_VERSION=0.1.0 \
        -f Dockerfile ..
    cd ..
done

# Start services with docker-compose
echo -e "${YELLOW}Iniciando servicios con docker-compose...${NC}"
if docker compose version &> /dev/null; then
    docker compose -f compose.yml up -d
else
    docker-compose -f compose.yml up -d
fi

# Wait for services to be healthy
echo -e "${YELLOW}Esperando que los servicios inicien (60 segundos)...${NC}"
sleep 60

# Display deployment status
echo -e "${GREEN}=========================================="
echo "Estado del Despliegue"
echo -e "==========================================${NC}"
if docker compose version &> /dev/null; then
    docker compose ps
else
    docker-compose ps
fi

echo -e "${GREEN}=========================================="
echo "Informacion de Acceso"
echo -e "==========================================${NC}"
echo "Eureka Dashboard: http://localhost:8761"
echo "API Gateway: http://localhost:8080"
echo "Swagger UI: http://localhost:8900/swagger-ui.html"
echo "Zipkin: http://localhost:9411"
echo ""
echo -e "${GREEN}Despliegue completado!${NC}"
echo ""
echo "Para detener:"
echo "  docker compose down"
echo ""
