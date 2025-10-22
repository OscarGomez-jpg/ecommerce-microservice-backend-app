#!/bin/bash

set -e

echo "=========================================="
echo "Deploying E-Commerce with Docker Compose"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}ERROR: docker is not installed${NC}"
    echo "Please install Docker first: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if docker-compose is available
if ! docker compose version &> /dev/null && ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}ERROR: docker-compose is not installed${NC}"
    echo "Please install Docker Compose first: https://docs.docker.com/compose/install/"
    exit 1
fi

# Build all microservices
echo -e "${YELLOW}Building microservices...${NC}"
./mvnw clean package -DskipTests

# Build Docker images for all services
echo -e "${YELLOW}Building Docker images...${NC}"

services=("service-discovery" "cloud-config" "api-gateway" "proxy-client" "user-service" "product-service" "order-service" "payment-service" "shipping-service" "favourite-service")

for service in "${services[@]}"; do
    echo -e "${YELLOW}Building image for ${service}...${NC}"
    cd ${service}
    docker build -t selimhorri/${service}-ecommerce-boot:0.1.0 --build-arg PROJECT_VERSION=0.1.0 -f Dockerfile ..
    cd ..
done

# Start services with docker-compose
echo -e "${YELLOW}Starting services with docker-compose...${NC}"
if docker compose version &> /dev/null; then
    docker compose -f compose.yml up -d
else
    docker-compose -f compose.yml up -d
fi

# Wait for services to be healthy
echo -e "${YELLOW}Waiting for services to start...${NC}"
sleep 30

# Check service health
echo -e "${YELLOW}Checking service health...${NC}"
services_health=(
    "service-discovery:8761"
    "cloud-config:9296"
    "api-gateway:8080"
    "proxy-client:8900"
    "user-service:8700"
    "product-service:8500"
    "order-service:8300"
    "payment-service:8400"
    "shipping-service:8600"
    "favourite-service:8800"
)

for service_port in "${services_health[@]}"; do
    service="${service_port%%:*}"
    port="${service_port##*:}"
    echo -n "Checking ${service}... "

    max_attempts=30
    attempt=1
    while [ $attempt -le $max_attempts ]; do
        if curl -f http://localhost:${port}/actuator/health &> /dev/null; then
            echo -e "${GREEN}OK${NC}"
            break
        fi
        if [ $attempt -eq $max_attempts ]; then
            echo -e "${YELLOW}TIMEOUT (service may still be starting)${NC}"
        fi
        sleep 2
        ((attempt++))
    done
done

# Display deployment status
echo -e "${GREEN}=========================================="
echo "Deployment Status"
echo -e "==========================================${NC}"
if docker compose version &> /dev/null; then
    docker compose ps
else
    docker-compose ps
fi

echo -e "${GREEN}=========================================="
echo "Access Information"
echo -e "==========================================${NC}"
echo "Service Discovery (Eureka): http://localhost:8761"
echo "API Gateway: http://localhost:8080"
echo "Proxy Client: http://localhost:8900"
echo "Zipkin (Tracing): http://localhost:9411"
echo ""
echo "Individual Services:"
echo "  User Service: http://localhost:8700"
echo "  Product Service: http://localhost:8500"
echo "  Order Service: http://localhost:8300"
echo "  Payment Service: http://localhost:8400"
echo "  Shipping Service: http://localhost:8600"
echo "  Favourite Service: http://localhost:8800"
echo ""
echo -e "${GREEN}=========================================="
echo "Deployment completed successfully!"
echo -e "==========================================${NC}"
echo ""
echo "To stop all services:"
echo "  docker compose down (or docker-compose down)"
echo ""
echo "To view logs:"
echo "  docker compose logs -f <service-name>"
