#!/bin/bash

echo "=========================================="
echo "Solucionador de Problemas Docker"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}[1] Deteniendo servicios existentes...${NC}"
if docker compose version &> /dev/null; then
    docker compose down 2>/dev/null || true
elif command -v docker-compose &> /dev/null; then
    docker-compose down 2>/dev/null || true
fi

echo -e "${GREEN}✓ Servicios detenidos${NC}"
echo ""

echo -e "${YELLOW}[2] Limpiando contenedores antiguos...${NC}"
docker container prune -f 2>/dev/null || true
echo -e "${GREEN}✓ Contenedores limpiados${NC}"
echo ""

echo -e "${YELLOW}[3] Verificando JARs compilados...${NC}"
if [ ! -f "user-service/target/user-service-v0.1.0.jar" ]; then
    echo -e "${RED}✗ JARs no encontrados${NC}"
    echo ""
    echo "Necesitas compilar primero:"
    echo "  ./scripts/build-with-docker.sh"
    echo ""
    exit 1
fi
echo -e "${GREEN}✓ JARs encontrados${NC}"
echo ""

echo -e "${YELLOW}[4] Construyendo imagenes Docker...${NC}"
echo "Esto puede tardar 5-10 minutos..."
echo ""

services=("service-discovery" "cloud-config" "api-gateway" "proxy-client" "user-service" "product-service" "order-service" "payment-service" "shipping-service" "favourite-service")

for service in "${services[@]}"; do
    echo -e "${YELLOW}Building ${service}...${NC}"
    cd ${service}
    docker build -t selimhorri/${service}-ecommerce-boot:0.1.0 \
        --build-arg PROJECT_VERSION=0.1.0 \
        -f Dockerfile .. 2>&1 | grep -E "(Successfully|ERROR|Step)" || true
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ ${service} construido${NC}"
    else
        echo -e "${RED}✗ Error construyendo ${service}${NC}"
    fi
    cd ..
done

echo ""
echo -e "${YELLOW}[5] Iniciando servicios con Docker Compose...${NC}"
echo ""

if docker compose version &> /dev/null; then
    docker compose -f compose.yml up -d
else
    docker-compose -f compose.yml up -d
fi

echo ""
echo -e "${YELLOW}[6] Esperando que los servicios inicien (60 segundos)...${NC}"
sleep 60

echo ""
echo -e "${GREEN}=========================================="
echo "Proceso completado"
echo -e "==========================================${NC}"
echo ""
echo "Verifica el estado con:"
echo "  ./scripts/check-status.sh"
echo ""
echo "Ver logs:"
echo "  ./scripts/show-logs.sh"
echo ""
