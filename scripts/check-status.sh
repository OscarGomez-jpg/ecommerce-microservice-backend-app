#!/bin/bash

echo "=========================================="
echo "Diagnostico del Sistema E-Commerce"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[1/5] Verificando compilacion...${NC}"
echo ""

# Check if JARs exist
JARS_OK=true
services=("service-discovery" "cloud-config" "api-gateway" "proxy-client" "user-service" "product-service" "order-service" "payment-service" "shipping-service" "favourite-service")

for service in "${services[@]}"; do
    jar_file="${service}/target/${service}-v0.1.0.jar"
    if [ -f "$jar_file" ]; then
        size=$(du -h "$jar_file" | cut -f1)
        echo -e "${GREEN}✓${NC} $service: $size"
    else
        echo -e "${RED}✗${NC} $service: JAR no encontrado"
        JARS_OK=false
    fi
done

echo ""
if [ "$JARS_OK" = false ]; then
    echo -e "${RED}ERROR: Faltan JARs. Ejecuta:${NC}"
    echo "  ./scripts/build-with-docker.sh"
    echo ""
fi

echo -e "${BLUE}[2/5] Verificando Docker...${NC}"
echo ""

# Check Docker
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓${NC} Docker instalado: $(docker --version)"
else
    echo -e "${RED}✗${NC} Docker no instalado"
fi

# Check Docker Compose
if docker compose version &> /dev/null; then
    echo -e "${GREEN}✓${NC} Docker Compose: $(docker compose version)"
elif command -v docker-compose &> /dev/null; then
    echo -e "${GREEN}✓${NC} Docker Compose: $(docker-compose --version)"
else
    echo -e "${RED}✗${NC} Docker Compose no instalado"
fi

echo ""
echo -e "${BLUE}[3/5] Verificando contenedores Docker...${NC}"
echo ""

# Check running containers
if docker ps &> /dev/null; then
    CONTAINER_COUNT=$(docker ps | grep -c "ecommerce" || echo "0")
    ALL_CONTAINER_COUNT=$(docker ps -a | grep -c "ecommerce" || echo "0")

    echo "Contenedores corriendo: $CONTAINER_COUNT"
    echo "Contenedores totales: $ALL_CONTAINER_COUNT"
    echo ""

    if [ "$CONTAINER_COUNT" -gt 0 ]; then
        echo "Estado de contenedores:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep ecommerce || docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        echo -e "${YELLOW}No hay contenedores corriendo${NC}"

        if [ "$ALL_CONTAINER_COUNT" -gt 0 ]; then
            echo ""
            echo "Contenedores detenidos:"
            docker ps -a --format "table {{.Names}}\t{{.Status}}" | grep ecommerce | head -10
        fi
    fi
else
    echo -e "${RED}No se puede conectar a Docker daemon${NC}"
    echo "Verifica que Docker este corriendo y que tu usuario este en el grupo docker"
fi

echo ""
echo -e "${BLUE}[4/5] Verificando servicios (si estan corriendo)...${NC}"
echo ""

# Check service health
services_to_check=(
    "service-discovery:8761:/actuator/health"
    "api-gateway:8080:/actuator/health"
    "user-service:8700:/actuator/health"
    "product-service:8500:/actuator/health"
)

for service_check in "${services_to_check[@]}"; do
    IFS=':' read -r name port path <<< "$service_check"

    if curl -sf "http://localhost:${port}${path}" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $name (puerto $port) - UP"
    else
        echo -e "${YELLOW}○${NC} $name (puerto $port) - No accesible"
    fi
done

echo ""
echo -e "${BLUE}[5/5] URLs de acceso...${NC}"
echo ""

if curl -sf "http://localhost:8761" > /dev/null 2>&1; then
    echo -e "${GREEN}Eureka Dashboard:${NC} http://localhost:8761"
    echo -e "${GREEN}API Gateway:${NC} http://localhost:8080"
    echo -e "${GREEN}Swagger UI:${NC} http://localhost:8900/swagger-ui.html"
    echo -e "${GREEN}Zipkin:${NC} http://localhost:9411"
else
    echo -e "${YELLOW}Los servicios no estan accesibles aun${NC}"
    echo ""
    echo "Si acabas de desplegar, espera 1-2 minutos"
    echo ""
    echo "URLs cuando esten listos:"
    echo "  Eureka Dashboard: http://localhost:8761"
    echo "  API Gateway: http://localhost:8080"
    echo "  Swagger UI: http://localhost:8900/swagger-ui.html"
    echo "  Zipkin: http://localhost:9411"
fi

echo ""
echo "=========================================="
echo "Fin del diagnostico"
echo "=========================================="
