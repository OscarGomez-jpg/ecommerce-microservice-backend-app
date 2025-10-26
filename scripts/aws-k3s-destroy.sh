#!/bin/bash

#############################################################
# AWS K3S Destroy Script
#
# IMPORTANTE: Este script ELIMINA TODOS los recursos creados
# para evitar cargos adicionales en AWS
#############################################################

set -e

echo "=============================================="
echo "AWS K3S Destruction - Eliminando Recursos"
echo "=============================================="
echo ""

# Verificar si existe archivo de configuración
if [ ! -f ~/.aws-k3s-deployment.conf ]; then
    echo "ERROR: No se encontró archivo de configuración"
    echo "No hay recursos para eliminar o fueron eliminados previamente"
    exit 1
fi

# Cargar configuración
source ~/.aws-k3s-deployment.conf

echo "Recursos a eliminar:"
echo "  Instance ID: $INSTANCE_ID"
echo "  Security Group: $SECURITY_GROUP_ID"
echo "  Key Name: $KEY_NAME"
echo "  Region: $REGION"
echo "  Deployed at: $DEPLOYED_AT"
echo ""
echo "ADVERTENCIA: Esta acción es IRREVERSIBLE"
read -p "¿Estás seguro? Escribe 'ELIMINAR' para continuar: " CONFIRM

if [ "$CONFIRM" != "ELIMINAR" ]; then
    echo "Operación cancelada"
    exit 0
fi

echo ""
echo "[1/5] Terminando instancia EC2..."
aws ec2 terminate-instances --region $REGION --instance-ids $INSTANCE_ID > /dev/null
echo "   Instancia $INSTANCE_ID terminada"

echo ""
echo "[2/5] Esperando a que la instancia se termine completamente..."
aws ec2 wait instance-terminated --region $REGION --instance-ids $INSTANCE_ID
echo "   Instancia terminada completamente"

echo ""
echo "[3/5] Eliminando Security Group..."
sleep 10  # Esperar a que se liberen las interfaces de red
aws ec2 delete-security-group --region $REGION --group-id $SECURITY_GROUP_ID 2>/dev/null || \
    echo "   ADVERTENCIA: No se pudo eliminar el security group. Inténtalo manualmente más tarde."

echo ""
echo "[4/5] Eliminando Key Pair..."
aws ec2 delete-key-pair --region $REGION --key-name $KEY_NAME
rm -f ~/.ssh/${KEY_NAME}.pem
echo "   Key pair eliminado"

echo ""
echo "[5/5] Limpiando archivos de configuración..."
rm -f ~/.aws-k3s-deployment.conf
rm -f /tmp/k3s-userdata.sh
rm -f /tmp/k3s-manifests.yaml
echo "   Archivos limpiados"

echo ""
echo "=============================================="
echo "RECURSOS ELIMINADOS EXITOSAMENTE"
echo "=============================================="
echo ""
echo "Verificando que no queden recursos..."
./scripts/aws-k3s-verify.sh
