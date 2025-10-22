#!/bin/bash

REPORT_FILE="debug-report-$(date +%Y%m%d-%H%M%S).txt"

echo "=========================================="
echo "Generando Reporte de Depuracion"
echo "=========================================="
echo ""
echo "Guardando en: $REPORT_FILE"
echo ""

{
    echo "=========================================="
    echo "REPORTE DE DEPURACION - E-COMMERCE"
    echo "Fecha: $(date)"
    echo "=========================================="
    echo ""

    echo "## 1. ESTADO DE COMPILACION"
    echo "----------------------------------------"
    echo ""
    for service in service-discovery cloud-config api-gateway proxy-client user-service product-service order-service payment-service shipping-service favourite-service; do
        if [ -f "${service}/target/${service}-v0.1.0.jar" ]; then
            size=$(du -h "${service}/target/${service}-v0.1.0.jar" | cut -f1)
            echo "[OK] $service: $size"
        else
            echo "[FALTA] $service: JAR no encontrado"
        fi
    done

    echo ""
    echo "## 2. VERSIONES DE SOFTWARE"
    echo "----------------------------------------"
    echo ""
    echo "Java:"
    java -version 2>&1 | head -1
    echo ""
    echo "Docker:"
    docker --version 2>&1
    echo ""
    echo "Docker Compose:"
    docker compose version 2>&1 || docker-compose --version 2>&1
    echo ""
    echo "Maven:"
    ./mvnw --version 2>&1 | head -1

    echo ""
    echo "## 3. ESTADO DE CONTENEDORES DOCKER"
    echo "----------------------------------------"
    echo ""
    docker ps -a 2>&1 | head -20

    echo ""
    echo "## 4. CONTENEDORES CORRIENDO"
    echo "----------------------------------------"
    echo ""
    docker ps 2>&1

    echo ""
    echo "## 5. IMAGENES DOCKER DISPONIBLES"
    echo "----------------------------------------"
    echo ""
    docker images | grep ecommerce 2>&1

    echo ""
    echo "## 6. VERIFICACION DE PUERTOS"
    echo "----------------------------------------"
    echo ""
    for port in 8761 8080 8900 8700 8500 8300 8400 8600 8800 9411; do
        if curl -sf "http://localhost:${port}/actuator/health" > /dev/null 2>&1; then
            echo "[UP] Puerto $port: Servicio respondiendo"
        elif nc -z localhost $port 2>/dev/null; then
            echo "[OCUPADO] Puerto $port: Algo escuchando pero no responde"
        else
            echo "[LIBRE] Puerto $port: Nada escuchando"
        fi
    done

    echo ""
    echo "## 7. LOGS RECIENTES (Ultimas 30 lineas por servicio)"
    echo "----------------------------------------"
    echo ""

    if docker compose version &> /dev/null; then
        for service in service-discovery-container api-gateway-container user-service-container; do
            echo ""
            echo "### Logs de $service:"
            echo "---"
            docker compose logs --tail=30 "$service" 2>&1 | head -30 || echo "No disponible"
        done
    fi

    echo ""
    echo "## 8. USO DE RECURSOS"
    echo "----------------------------------------"
    echo ""
    docker stats --no-stream 2>&1 | head -15

    echo ""
    echo "## 9. PROBLEMAS DETECTADOS"
    echo "----------------------------------------"
    echo ""

    PROBLEMS=0

    # Check JARs
    if [ ! -f "user-service/target/user-service-v0.1.0.jar" ]; then
        echo "[PROBLEMA] JARs no compilados"
        PROBLEMS=$((PROBLEMS + 1))
    fi

    # Check Docker
    if ! docker ps &> /dev/null; then
        echo "[PROBLEMA] No se puede conectar a Docker daemon"
        PROBLEMS=$((PROBLEMS + 1))
    fi

    # Check containers
    RUNNING=$(docker ps 2>/dev/null | grep -c ecommerce || echo "0")
    if [ "$RUNNING" -eq 0 ]; then
        echo "[PROBLEMA] No hay contenedores corriendo"
        PROBLEMS=$((PROBLEMS + 1))
    fi

    # Check services
    if ! curl -sf "http://localhost:8761" > /dev/null 2>&1; then
        echo "[PROBLEMA] Eureka (8761) no accesible"
        PROBLEMS=$((PROBLEMS + 1))
    fi

    if [ $PROBLEMS -eq 0 ]; then
        echo "[OK] No se detectaron problemas criticos"
    else
        echo ""
        echo "Total de problemas encontrados: $PROBLEMS"
    fi

    echo ""
    echo "## 10. RECOMENDACIONES"
    echo "----------------------------------------"
    echo ""

    if [ ! -f "user-service/target/user-service-v0.1.0.jar" ]; then
        echo "1. Compilar proyecto:"
        echo "   ./scripts/build-with-docker.sh"
        echo ""
    fi

    if [ "$RUNNING" -eq 0 ]; then
        echo "2. Desplegar servicios:"
        echo "   ./scripts/fix-docker.sh"
        echo ""
    fi

    echo "3. Verificar estado:"
    echo "   ./scripts/check-status.sh"
    echo ""

    echo "4. Ver logs:"
    echo "   ./scripts/show-logs.sh [servicio]"
    echo ""

    echo ""
    echo "=========================================="
    echo "FIN DEL REPORTE"
    echo "=========================================="

} > "$REPORT_FILE" 2>&1

echo ""
echo "Reporte generado: $REPORT_FILE"
echo ""
echo "Ver reporte:"
echo "  cat $REPORT_FILE"
echo ""
echo "O ver resumen rapido:"
echo "  grep -E '\[PROBLEMA\]|\[OK\]' $REPORT_FILE"
echo ""
