#!/bin/bash

set -e

echo "=========================================="
echo "Deploying E-Commerce to AWS EKS"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
CLUSTER_NAME="ecommerce-cluster"
REGION="us-east-1"
NODE_TYPE="t3.medium"
MIN_NODES=1
MAX_NODES=3
NAMESPACE="prod"

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}AWS CLI is not configured. Please run 'aws configure' first.${NC}"
    exit 1
fi

# Check if cluster exists
if ! eksctl get cluster --name $CLUSTER_NAME --region $REGION &> /dev/null; then
    echo -e "${YELLOW}Creating EKS cluster... (this may take 15-20 minutes)${NC}"
    eksctl create cluster \
        --name $CLUSTER_NAME \
        --region $REGION \
        --nodegroup-name standard-workers \
        --node-type $NODE_TYPE \
        --nodes 2 \
        --nodes-min $MIN_NODES \
        --nodes-max $MAX_NODES \
        --managed
else
    echo -e "${GREEN}EKS cluster already exists${NC}"
fi

# Update kubeconfig
echo -e "${YELLOW}Updating kubeconfig...${NC}"
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

# Create namespaces
echo -e "${YELLOW}Creating namespaces...${NC}"
kubectl apply -f k8s/namespaces/prod-namespace.yaml

# Create Docker registry secret
echo -e "${YELLOW}Creating Docker registry secret...${NC}"
read -p "Enter your Docker Hub username: " DOCKER_USER
read -sp "Enter your Docker Hub password/token: " DOCKER_PASS
echo

kubectl create secret docker-registry dockerhub-secret \
    --docker-server=https://index.docker.io/v1/ \
    --docker-username=$DOCKER_USER \
    --docker-password=$DOCKER_PASS \
    --docker-email=your-email@example.com \
    -n $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Update image names in deployment files to use your Docker Hub username
echo -e "${YELLOW}Updating deployment files with your Docker username...${NC}"
find k8s -name "*.yaml" -type f -exec sed -i "s|selimhorri|$DOCKER_USER|g" {} \;

# Deploy infrastructure services
echo -e "${YELLOW}Deploying infrastructure services...${NC}"
kubectl apply -f k8s/infrastructure/service-discovery/deployment.yaml -n $NAMESPACE
kubectl apply -f k8s/infrastructure/api-gateway/deployment.yaml -n $NAMESPACE

# Wait for service discovery to be ready
echo -e "${YELLOW}Waiting for service-discovery to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=service-discovery -n $NAMESPACE --timeout=300s

# Deploy microservices
echo -e "${YELLOW}Deploying microservices...${NC}"
kubectl apply -f k8s/services/user-service/deployment.yaml -n $NAMESPACE
kubectl apply -f k8s/services/product-service/deployment.yaml -n $NAMESPACE
kubectl apply -f k8s/services/order-service/deployment.yaml -n $NAMESPACE
kubectl apply -f k8s/services/payment-service/deployment.yaml -n $NAMESPACE
kubectl apply -f k8s/services/shipping-service/deployment.yaml -n $NAMESPACE
kubectl apply -f k8s/services/favourite-service/deployment.yaml -n $NAMESPACE

# Wait for all deployments to be ready
echo -e "${YELLOW}Waiting for all services to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=user-service -n $NAMESPACE --timeout=600s
kubectl wait --for=condition=ready pod -l app=product-service -n $NAMESPACE --timeout=600s
kubectl wait --for=condition=ready pod -l app=order-service -n $NAMESPACE --timeout=600s
kubectl wait --for=condition=ready pod -l app=payment-service -n $NAMESPACE --timeout=600s
kubectl wait --for=condition=ready pod -l app=shipping-service -n $NAMESPACE --timeout=600s
kubectl wait --for=condition=ready pod -l app=favourite-service -n $NAMESPACE --timeout=600s

# Display deployment status
echo -e "${GREEN}=========================================="
echo "Deployment Status"
echo -e "==========================================${NC}"
kubectl get pods -n $NAMESPACE
kubectl get services -n $NAMESPACE

# Get Load Balancer URL
echo -e "${YELLOW}Getting Load Balancer URL...${NC}"
LB_URL=$(kubectl get svc api-gateway -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
if [ -z "$LB_URL" ]; then
    LB_URL=$(kubectl get svc api-gateway -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
fi

echo -e "${GREEN}=========================================="
echo "Access Information"
echo -e "==========================================${NC}"
if [ -n "$LB_URL" ]; then
    echo "API Gateway URL: http://$LB_URL:8080"
else
    echo "Load Balancer is provisioning... Check again in a few minutes with:"
    echo "  kubectl get svc api-gateway -n $NAMESPACE"
fi
echo ""
echo "To access services locally with port-forward:"
echo "  kubectl port-forward svc/api-gateway 8080:8080 -n $NAMESPACE"
echo ""
echo "To view logs:"
echo "  kubectl logs -f deployment/user-service -n $NAMESPACE"
echo -e "${GREEN}=========================================="
echo "Deployment completed successfully!"
echo -e "==========================================${NC}"

echo ""
echo -e "${YELLOW}IMPORTANT: Remember to monitor your AWS costs!${NC}"
echo "To delete the cluster and avoid charges:"
echo "  ./scripts/cleanup-aws.sh"
