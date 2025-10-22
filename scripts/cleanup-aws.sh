#!/bin/bash

set -e

echo "=========================================="
echo "Cleaning up AWS EKS Resources"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
CLUSTER_NAME="ecommerce-cluster"
REGION="us-east-1"
NAMESPACE="prod"

echo -e "${RED}WARNING: This will delete all resources in the EKS cluster!${NC}"
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

# Update kubeconfig
echo -e "${YELLOW}Updating kubeconfig...${NC}"
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME 2>/dev/null || true

# Delete all resources in the namespace
echo -e "${YELLOW}Deleting all resources in namespace $NAMESPACE...${NC}"
kubectl delete all --all -n $NAMESPACE 2>/dev/null || true

# Delete the namespace
echo -e "${YELLOW}Deleting namespace...${NC}"
kubectl delete namespace $NAMESPACE 2>/dev/null || true

# Delete the EKS cluster
echo -e "${YELLOW}Deleting EKS cluster... (this may take 10-15 minutes)${NC}"
eksctl delete cluster --name $CLUSTER_NAME --region $REGION --wait

echo -e "${GREEN}=========================================="
echo "Cleanup completed successfully!"
echo -e "==========================================${NC}"
echo ""
echo "Please verify in AWS Console that all resources have been deleted:"
echo "1. EC2 instances"
echo "2. Load Balancers"
echo "3. EBS volumes"
echo "4. Security Groups"
echo "5. VPC (if created by eksctl)"
