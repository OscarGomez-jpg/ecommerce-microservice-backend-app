#!/bin/bash

#############################################################
# AWS K3S Verify Script
#
# Verifica que NO queden recursos activos generando costos
#############################################################

REGION="${AWS_REGION:-us-east-1}"

echo "=============================================="
echo "Verificación de Recursos AWS"
echo "=============================================="
echo ""
echo "Región: $REGION"
echo ""

# Verificar instancias EC2
echo "[1/4] Verificando instancias EC2..."
INSTANCES=$(aws ec2 describe-instances \
    --region $REGION \
    --filters "Name=tag:Project,Values=ecommerce-microservices" \
              "Name=instance-state-name,Values=running,pending,stopping,stopped" \
    --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType,PublicIpAddress,Tags[?Key==`Name`].Value|[0]]' \
    --output text)

if [ -z "$INSTANCES" ]; then
    echo "   ✓ No hay instancias EC2 activas"
else
    echo "   ⚠ ADVERTENCIA: Se encontraron instancias EC2:"
    echo "$INSTANCES" | while read line; do
        echo "     $line"
    done
    echo ""
    echo "   Para eliminarlas:"
    echo "   aws ec2 terminate-instances --region $REGION --instance-ids <INSTANCE_ID>"
fi

# Verificar Security Groups
echo ""
echo "[2/4] Verificando Security Groups..."
SG_COUNT=$(aws ec2 describe-security-groups \
    --region $REGION \
    --filters "Name=group-name,Values=ecommerce-k3s-sg" \
    --query 'length(SecurityGroups)' \
    --output text)

if [ "$SG_COUNT" == "0" ]; then
    echo "   ✓ No hay security groups personalizados"
else
    echo "   ⚠ ADVERTENCIA: Se encontraron $SG_COUNT security groups"
    aws ec2 describe-security-groups \
        --region $REGION \
        --filters "Name=group-name,Values=ecommerce-k3s-sg" \
        --query 'SecurityGroups[*].[GroupId,GroupName]' \
        --output text | while read line; do
        echo "     $line"
    done
    echo ""
    echo "   Para eliminarlos:"
    echo "   aws ec2 delete-security-group --region $REGION --group-id <GROUP_ID>"
fi

# Verificar Key Pairs
echo ""
echo "[3/4] Verificando Key Pairs..."
KEY_PAIRS=$(aws ec2 describe-key-pairs \
    --region $REGION \
    --filters "Name=key-name,Values=ecommerce-k3s-key-*" \
    --query 'KeyPairs[*].KeyName' \
    --output text)

if [ -z "$KEY_PAIRS" ]; then
    echo "   ✓ No hay key pairs personalizados"
else
    echo "   ⚠ ADVERTENCIA: Se encontraron key pairs:"
    echo "     $KEY_PAIRS"
    echo ""
    echo "   Para eliminarlos:"
    for key in $KEY_PAIRS; do
        echo "   aws ec2 delete-key-pair --region $REGION --key-name $key"
    done
fi

# Verificar volúmenes EBS huérfanos
echo ""
echo "[4/4] Verificando volúmenes EBS disponibles..."
VOLUMES=$(aws ec2 describe-volumes \
    --region $REGION \
    --filters "Name=status,Values=available" \
    --query 'Volumes[*].[VolumeId,Size,State]' \
    --output text)

if [ -z "$VOLUMES" ]; then
    echo "   ✓ No hay volúmenes EBS huérfanos"
else
    echo "   ⚠ ADVERTENCIA: Se encontraron volúmenes EBS no asociados:"
    echo "$VOLUMES" | while read line; do
        echo "     $line"
    done
    echo ""
    echo "   Para eliminarlos:"
    echo "   aws ec2 delete-volume --region $REGION --volume-id <VOLUME_ID>"
fi

# Estimación de costos
echo ""
echo "=============================================="
echo "Estimación de Costos (si hay recursos activos)"
echo "=============================================="
echo ""

# Contar instancias activas
ACTIVE_INSTANCES=$(echo "$INSTANCES" | grep -c "running" || echo "0")

if [ "$ACTIVE_INSTANCES" -gt 0 ]; then
    echo "Instancias t2.small activas: $ACTIVE_INSTANCES"
    echo "Costo estimado:"
    echo "  Por hora: \$$(echo "$ACTIVE_INSTANCES * 0.023" | bc)"
    echo "  Por día: \$$(echo "$ACTIVE_INSTANCES * 0.023 * 24" | bc)"
    echo "  Por 72 horas: \$$(echo "$ACTIVE_INSTANCES * 0.023 * 72" | bc)"
    echo ""
    echo "⚠ IMPORTANTE: Elimina estos recursos con ./scripts/aws-k3s-destroy.sh"
else
    echo "✓ No hay recursos generando costos"
fi

echo ""
echo "=============================================="

# Verificar configuración local
echo ""
echo "Verificando archivos locales..."
if [ -f ~/.aws-k3s-deployment.conf ]; then
    echo "   ⚠ Archivo de configuración existe: ~/.aws-k3s-deployment.conf"
    echo "   Contenido:"
    cat ~/.aws-k3s-deployment.conf | sed 's/^/     /'
else
    echo "   ✓ No hay archivos de configuración locales"
fi

echo ""
