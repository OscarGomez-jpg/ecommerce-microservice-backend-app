#!/bin/bash

echo "=========================================="
echo "Logs de Servicios Docker"
echo "=========================================="
echo ""

SERVICE=$1

if [ -z "$SERVICE" ]; then
    echo "Ver logs de todos los servicios (ultimas 50 lineas de cada uno):"
    echo ""

    if docker compose version &> /dev/null; then
        docker compose logs --tail=50
    elif command -v docker-compose &> /dev/null; then
        docker-compose logs --tail=50
    else
        echo "Docker Compose no disponible"
        exit 1
    fi
else
    echo "Ver logs de: $SERVICE"
    echo ""

    if docker compose version &> /dev/null; then
        docker compose logs -f "$SERVICE"
    elif command -v docker-compose &> /dev/null; then
        docker-compose logs -f "$SERVICE"
    else
        echo "Docker Compose no disponible"
        exit 1
    fi
fi

echo ""
echo "=========================================="
echo "Servicios disponibles:"
echo "=========================================="
echo "  user-service"
echo "  product-service"
echo "  order-service"
echo "  payment-service"
echo "  shipping-service"
echo "  favourite-service"
echo "  service-discovery"
echo "  api-gateway"
echo "  proxy-client"
echo "  cloud-config"
echo "  zipkin"
echo ""
echo "Uso:"
echo "  ./scripts/show-logs.sh [nombre-servicio]"
echo ""
echo "Ejemplos:"
echo "  ./scripts/show-logs.sh user-service"
echo "  ./scripts/show-logs.sh"
