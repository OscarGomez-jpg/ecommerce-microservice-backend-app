#!/bin/bash

set -e

echo "=========================================="
echo "Compilando con Docker (Java 11)"
echo "=========================================="
echo "Tu Java local no sera modificado"
echo ""

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

PROJECT_DIR="/home/osgomez/Code/icesi_codes/8vo_semestre/ingesoft_V/taller_2/ecommerce-microservice-backend-app"

echo -e "${YELLOW}Compilando con Maven usando Docker (Java 11)...${NC}"
echo "Esto puede tardar 5-10 minutos la primera vez..."
echo ""

# Usar imagen oficial de Maven con Java 11 para compilar
# Compilamos SIN ejecutar tests para evitar problemas de compatibilidad
docker run --rm \
  -v "$PROJECT_DIR":/usr/src/app \
  -v "$HOME/.m2":/root/.m2 \
  -w /usr/src/app \
  maven:3.8.6-openjdk-11 \
  mvn clean package -DskipTests -Dmaven.test.skip=true

echo ""
echo -e "${GREEN}=========================================="
echo "Compilacion completada!"
echo -e "==========================================${NC}"
echo ""
echo "Ahora puedes desplegar con Docker Compose:"
echo "  ./scripts/deploy-docker-compose-prebuilt.sh"
echo ""
