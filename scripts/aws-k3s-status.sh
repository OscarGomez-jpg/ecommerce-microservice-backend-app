#!/bin/bash

#############################################################
# AWS K3S Status Script
#
# Muestra el estado actual del deployment y costos acumulados
#############################################################

if [ ! -f ~/.aws-k3s-deployment.conf ]; then
    echo "ERROR: No hay deployment activo"
    echo "Ejecuta ./scripts/aws-k3s-deploy.sh primero"
    exit 1
fi

source ~/.aws-k3s-deployment.conf

echo "=============================================="
echo "Estado del Deployment K3S"
echo "=============================================="
echo ""
echo "Información básica:"
echo "  Instance ID: $INSTANCE_ID"
echo "  IP Pública: $PUBLIC_IP"
echo "  Región: $REGION"
echo "  Desplegado: $DEPLOYED_AT"
echo ""

# Calcular tiempo activo
DEPLOYED_EPOCH=$(date -d "$DEPLOYED_AT" +%s 2>/dev/null || echo "0")
CURRENT_EPOCH=$(date +%s)
HOURS_ACTIVE=$(echo "scale=2; ($CURRENT_EPOCH - $DEPLOYED_EPOCH) / 3600" | bc)
COST=$(echo "scale=2; $HOURS_ACTIVE * 0.023" | bc)

echo "Tiempo activo:"
echo "  Horas: $HOURS_ACTIVE"
echo "  Costo acumulado: \$$COST USD"
echo "  Costo proyectado 72h: \$1.66 USD"
echo ""

# Verificar estado de la instancia
echo "Estado de la instancia EC2:"
INSTANCE_STATE=$(aws ec2 describe-instances \
    --region $REGION \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].State.Name' \
    --output text 2>/dev/null || echo "unknown")

if [ "$INSTANCE_STATE" == "running" ]; then
    echo "  ✓ Instancia RUNNING"
elif [ "$INSTANCE_STATE" == "stopped" ]; then
    echo "  ⚠ Instancia STOPPED (sin cargos de compute, pero EBS sí cobra)"
elif [ "$INSTANCE_STATE" == "terminated" ]; then
    echo "  ✓ Instancia TERMINATED (sin cargos)"
else
    echo "  ⚠ Estado: $INSTANCE_STATE"
fi

echo ""
echo "Acceso SSH:"
echo "  ssh -i ~/.ssh/${KEY_NAME}.pem ubuntu@${PUBLIC_IP}"
echo ""

# Verificar pods si la instancia está running
if [ "$INSTANCE_STATE" == "running" ]; then
    echo "Estado de los pods (esto puede tardar un momento)..."
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i ~/.ssh/${KEY_NAME}.pem ubuntu@${PUBLIC_IP} \
        "sudo k3s kubectl get pods -n ecommerce" 2>/dev/null || echo "  No se pudo conectar o k3s no está listo"

    echo ""
    echo "Servicios disponibles:"
    echo "  - Eureka Dashboard: http://${PUBLIC_IP}:30761"
    echo "  - API Gateway: http://${PUBLIC_IP}:30080"
fi

echo ""
echo "=============================================="
echo ""
echo "Para eliminar el deployment y detener cargos:"
echo "  ./scripts/aws-k3s-destroy.sh"
echo ""
