#!/bin/bash

# Script para poblar datos de prueba en los servicios
# Se ejecuta antes de los Load Tests

set -e

MINIKUBE_IP=${1:-192.168.49.2}
API_URL="http://${MINIKUBE_IP}:30080"

echo "🔧 Poblando datos de prueba en: ${API_URL}"
echo ""

# Crear productos de prueba
echo "📦 Creando productos..."
for i in {1..20}; do
  curl -s -X POST "${API_URL}/product-service/api/products" \
    -H "Content-Type: application/json" \
    -d "{
      \"productTitle\": \"Product ${i}\",
      \"sku\": \"SKU${i}\",
      \"priceUnit\": $(( RANDOM % 100 + 10 )),
      \"quantity\": $(( RANDOM % 100 + 1 )),
      \"category\": {
        \"categoryTitle\": \"electronics\"
      }
    }" > /dev/null 2>&1 || true
done
echo "✅ 20 productos creados"

# Crear usuarios de prueba
echo "👥 Creando usuarios..."
for i in {1..10}; do
  curl -s -X POST "${API_URL}/user-service/api/users" \
    -H "Content-Type: application/json" \
    -d "{
      \"firstName\": \"User\",
      \"lastName\": \"${i}\",
      \"email\": \"user${i}@test.com\",
      \"phone\": \"123456789${i}\"
    }" > /dev/null 2>&1 || true
done
echo "✅ 10 usuarios creados"

# Crear algunas órdenes
echo "🛒 Creando órdenes..."
for i in {1..5}; do
  curl -s -X POST "${API_URL}/order-service/api/orders" \
    -H "Content-Type: application/json" \
    -d "{
      \"orderDesc\": \"Test Order ${i}\",
      \"orderDate\": \"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)\",
      \"orderFee\": $(( RANDOM % 100 + 20 ))
    }" > /dev/null 2>&1 || true
done
echo "✅ 5 órdenes creadas"

# Crear pagos (skip si payment-service no está disponible)
echo "💳 Creando pagos..."
if curl -s -f "${API_URL}/payment-service/actuator/health" > /dev/null 2>&1; then
  for i in {1..5}; do
    curl -s -X POST "${API_URL}/payment-service/api/payments" \
      -H "Content-Type: application/json" \
      -d "{
        \"isPayed\": $([ $((RANDOM % 2)) -eq 0 ] && echo "true" || echo "false"),
        \"paymentAmount\": $(( RANDOM % 200 + 50 ))
      }" > /dev/null 2>&1 || true
  done
  echo "✅ 5 pagos creados"
else
  echo "⚠️  Payment service no disponible - saltando"
fi

echo ""
echo "🎉 Datos de prueba poblados exitosamente!"
echo ""
echo "Puedes verificar:"
echo "  curl ${API_URL}/product-service/api/products"
echo "  curl ${API_URL}/user-service/api/users"
echo "  curl ${API_URL}/order-service/api/orders"
