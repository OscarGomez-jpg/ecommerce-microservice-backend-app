#!/bin/bash

set -e

echo "=========================================="
echo "Verificación de Microservicios en Minikube"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PASS=0
FAIL=0

# Función para verificar
check() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((PASS++))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        ((FAIL++))
        return 1
    fi
}

# Test 1: Namespace existe
echo -n "1. Namespace 'ecommerce' existe... "
kubectl get namespace ecommerce &>/dev/null
check

# Test 2: Contar pods
echo -n "2. Pods desplegados... "
POD_COUNT=$(kubectl get pods -n ecommerce --no-headers 2>/dev/null | wc -l)
echo -n "($POD_COUNT pods) "
if [ "$POD_COUNT" -ge 6 ]; then
    check
else
    false
    check
fi

# Test 3: Todos los pods Running
echo -n "3. Todos los pods en estado Running... "
NOT_RUNNING=$(kubectl get pods -n ecommerce --no-headers 2>/dev/null | grep -v "Running" | wc -l)
if [ "$NOT_RUNNING" -eq 0 ] && [ "$POD_COUNT" -ge 6 ]; then
    check
else
    false
    check
    echo -e "${YELLOW}   Pods con problemas:${NC}"
    kubectl get pods -n ecommerce | grep -v "Running" | grep -v "NAME"
fi

# Test 4: Todos los pods Ready (1/1)
echo -n "4. Todos los pods Ready (1/1)... "
NOT_READY=$(kubectl get pods -n ecommerce --no-headers 2>/dev/null | grep -v "1/1" | wc -l)
if [ "$NOT_READY" -eq 0 ] && [ "$POD_COUNT" -ge 6 ]; then
    check
else
    false
    check
    echo -e "${YELLOW}   Pods no listos:${NC}"
    kubectl get pods -n ecommerce | grep -v "1/1" | grep -v "NAME"
fi

# Test 5: Servicios creados
echo -n "5. Servicios creados... "
SERVICE_COUNT=$(kubectl get svc -n ecommerce --no-headers 2>/dev/null | wc -l)
echo -n "($SERVICE_COUNT servicios) "
if [ "$SERVICE_COUNT" -ge 6 ]; then
    check
else
    false
    check
fi

# Test 6: Eureka accesible
echo -n "6. Eureka Dashboard accesible... "
MINIKUBE_IP=$(minikube ip 2>/dev/null)
EUREKA_URL="http://$MINIKUBE_IP:30761"
curl -s -o /dev/null -w "%{http_code}" "$EUREKA_URL" | grep -q "200"
check

# Test 7: Zipkin accesible
echo -n "7. Zipkin UI accesible... "
ZIPKIN_URL="http://$MINIKUBE_IP:30411"
curl -s -o /dev/null -w "%{http_code}" "$ZIPKIN_URL" | grep -q "200"
check

# Test 8: API Gateway accesible
echo -n "8. API Gateway accesible... "
GATEWAY_URL="http://$MINIKUBE_IP:30080"
curl -s -o /dev/null -w "%{http_code}" "$GATEWAY_URL/actuator/health" | grep -q "200"
check

# Test 9: Servicios registrados en Eureka
echo -n "9. Servicios registrados en Eureka... "
EUREKA_APPS=$(curl -s "$EUREKA_URL/eureka/apps" 2>/dev/null | grep -o "<name>[^<]*</name>" | wc -l)
echo -n "($EUREKA_APPS apps) "
if [ "$EUREKA_APPS" -ge 4 ]; then
    check
else
    false
    check
fi

# Test 10: User service responde
echo -n "10. User service responde a través del gateway... "
curl -s "$GATEWAY_URL/user-service/actuator/health" | grep -q "UP"
check

echo ""
echo "=========================================="
echo "DETALLE DE RECURSOS"
echo "=========================================="

echo ""
echo -e "${BLUE}=== Pods ===${NC}"
kubectl get pods -n ecommerce

echo ""
echo -e "${BLUE}=== Servicios ===${NC}"
kubectl get svc -n ecommerce

echo ""
echo -e "${BLUE}=== URLs de Acceso ===${NC}"
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

echo ""
echo "=========================================="
echo "RESUMEN"
echo "=========================================="
echo -e "${GREEN}Tests pasados: $PASS${NC}"
echo -e "${RED}Tests fallidos: $FAIL${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✓ Todos los microservicios funcionan CORRECTAMENTE${NC}"
    echo ""
    echo "Comandos útiles:"
    echo "  Ver logs: kubectl logs -n ecommerce -l app=user-service -f"
    echo "  Port-forward: kubectl port-forward -n ecommerce svc/user-service 8700:8700"
    echo "  Restart pod: kubectl rollout restart deployment user-service -n ecommerce"
    exit 0
else
    echo -e "${RED}✗ Algunos microservicios tienen problemas${NC}"
    echo ""
    echo "Comandos de diagnóstico:"
    echo "  Ver logs de un pod: kubectl logs -n ecommerce <POD-NAME>"
    echo "  Describir pod: kubectl describe pod -n ecommerce <POD-NAME>"
    echo "  Ver eventos: kubectl get events -n ecommerce --sort-by='.lastTimestamp'"
    exit 1
fi
