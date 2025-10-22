#!/bin/bash

echo "============================================"
echo "Despliegue Simplificado - 6 Microservicios"
echo "============================================"
echo ""

echo "Servicios a desplegar:"
echo "  1. Zipkin (trazabilidad)"
echo "  2. Service Discovery (Eureka)"
echo "  3. API Gateway"
echo "  4. User Service"
echo "  5. Product Service"
echo "  6. Order Service"
echo ""

echo "[1/4] Deteniendo contenedores existentes..."
docker compose down 2>/dev/null || true
echo ""

echo "[2/4] Compilando servicios con Java 11..."
./scripts/build-with-docker.sh
if [ $? -ne 0 ]; then
    echo "Error en la compilación. Abortando."
    exit 1
fi
echo ""

echo "[3/4] Construyendo imágenes Docker..."
docker compose build --no-cache
if [ $? -ne 0 ]; then
    echo "Error construyendo imágenes. Abortando."
    exit 1
fi
echo ""

echo "[4/4] Iniciando servicios..."
docker compose up -d
if [ $? -ne 0 ]; then
    echo "Error iniciando servicios. Abortando."
    exit 1
fi
echo ""

echo "Esperando 40 segundos para que los servicios inicien..."
sleep 40
echo ""

echo "Verificando despliegue..."
./scripts/verify-deployment.sh
echo ""

echo "============================================"
echo "Despliegue completado!"
echo ""
echo "Accesos:"
echo "  - Eureka: http://localhost:8761"
echo "  - Zipkin: http://localhost:9411"
echo "  - API Gateway: http://localhost:8080"
echo ""
echo "Para ver logs: docker compose logs -f [service-name]"
echo "Para detener: docker compose down"
echo "============================================"
