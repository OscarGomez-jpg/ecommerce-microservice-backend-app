#!/bin/bash

echo "=========================================="
echo "Verificación de Despliegue Docker Compose"
echo "=========================================="
echo ""

echo "1. Verificando Eureka Service Discovery (http://localhost:8761)..."
EUREKA_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8761)
if [ "$EUREKA_STATUS" == "200" ]; then
    echo "   ✓ Eureka está respondiendo"

    # Esperar un poco más para que los servicios se registren
    echo "   Esperando 30 segundos para que los servicios se registren..."
    sleep 30

    echo ""
    echo "2. Servicios registrados en Eureka:"
    curl -s -H "Accept: application/json" http://localhost:8761/eureka/apps | \
        python3 -c "import sys, json; apps = json.load(sys.stdin).get('applications', {}).get('application', []); [print(f\"   - {app['name']}: {len(app.get('instance', []))} instancias\") for app in (apps if isinstance(apps, list) else [apps])]" 2>/dev/null

    if [ $? -ne 0 ]; then
        echo "   (No se pudo parsear la respuesta de Eureka o aún no hay servicios registrados)"
    fi
else
    echo "   ✗ Eureka no está respondiendo (HTTP $EUREKA_STATUS)"
fi

echo ""
echo "3. Verificando Zipkin (http://localhost:9411)..."
ZIPKIN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9411)
if [ "$ZIPKIN_STATUS" == "200" ]; then
    echo "   ✓ Zipkin está respondiendo"
else
    echo "   ✗ Zipkin no está respondiendo (HTTP $ZIPKIN_STATUS)"
fi

echo ""
echo "4. Verificando API Gateway (http://localhost:8080)..."
GATEWAY_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/actuator/health 2>/dev/null)
if [ "$GATEWAY_STATUS" == "200" ]; then
    echo "   ✓ API Gateway está respondiendo"
else
    echo "   ℹ API Gateway status: HTTP $GATEWAY_STATUS (puede estar iniciando aún)"
fi

echo ""
echo "5. Verificando servicios individuales:"

declare -A SERVICES=(
    ["user-service"]="8700"
    ["product-service"]="8500"
    ["order-service"]="8300"
    ["payment-service"]="8400"
    ["shipping-service"]="8600"
    ["favourite-service"]="8800"
)

for SERVICE in "${!SERVICES[@]}"; do
    PORT="${SERVICES[$SERVICE]}"
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$PORT/$SERVICE/actuator/health 2>/dev/null)
    if [ "$STATUS" == "200" ]; then
        echo "   ✓ $SERVICE (port $PORT) está respondiendo"
    else
        echo "   ℹ $SERVICE (port $PORT) status: HTTP $STATUS"
    fi
done

echo ""
echo "=========================================="
echo "Accesos disponibles:"
echo "  - Eureka Dashboard: http://localhost:8761"
echo "  - Zipkin: http://localhost:9411"
echo "  - API Gateway: http://localhost:8080"
echo "=========================================="
