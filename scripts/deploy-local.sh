#!/bin/bash

set -e

echo "=========================================="
echo "Deploying E-Commerce to Local Minikube"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if minikube is running
if ! minikube status &> /dev/null; then
    echo -e "${YELLOW}Starting Minikube...${NC}"
    minikube start --cpus=4 --memory=8192 --driver=docker
else
    echo -e "${GREEN}Minikube is already running${NC}"
fi

# Set kubectl context to minikube
kubectl config use-context minikube

# Create namespaces
echo -e "${YELLOW}Creating namespaces...${NC}"
kubectl apply -f k8s/namespaces/

# Create Docker registry secret (you need to set your credentials)
echo -e "${YELLOW}Creating Docker registry secret...${NC}"
read -p "Enter your Docker Hub username: " DOCKER_USER
read -sp "Enter your Docker Hub password/token: " DOCKER_PASS
echo

for ns in dev stage; do
    kubectl create secret docker-registry dockerhub-secret \
        --docker-server=https://index.docker.io/v1/ \
        --docker-username=$DOCKER_USER \
        --docker-password=$DOCKER_PASS \
        --docker-email=your-email@example.com \
        -n $ns --dry-run=client -o yaml | kubectl apply -f -
done

# Deploy infrastructure services
echo -e "${YELLOW}Deploying infrastructure services...${NC}"
kubectl apply -f k8s/infrastructure/service-discovery/deployment.yaml -n dev
kubectl apply -f k8s/infrastructure/api-gateway/deployment.yaml -n dev

# Wait for service discovery to be ready
echo -e "${YELLOW}Waiting for service-discovery to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=service-discovery -n dev --timeout=300s

# Deploy microservices
echo -e "${YELLOW}Deploying microservices...${NC}"
kubectl apply -f k8s/services/user-service/deployment.yaml -n dev
kubectl apply -f k8s/services/product-service/deployment.yaml -n dev
kubectl apply -f k8s/services/order-service/deployment.yaml -n dev
kubectl apply -f k8s/services/payment-service/deployment.yaml -n dev
kubectl apply -f k8s/services/shipping-service/deployment.yaml -n dev
kubectl apply -f k8s/services/favourite-service/deployment.yaml -n dev

# Wait for all deployments to be ready
echo -e "${YELLOW}Waiting for all services to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=user-service -n dev --timeout=300s
kubectl wait --for=condition=ready pod -l app=product-service -n dev --timeout=300s
kubectl wait --for=condition=ready pod -l app=order-service -n dev --timeout=300s
kubectl wait --for=condition=ready pod -l app=payment-service -n dev --timeout=300s
kubectl wait --for=condition=ready pod -l app=shipping-service -n dev --timeout=300s
kubectl wait --for=condition=ready pod -l app=favourite-service -n dev --timeout=300s

# Display deployment status
echo -e "${GREEN}=========================================="
echo "Deployment Status"
echo -e "==========================================${NC}"
kubectl get pods -n dev
kubectl get services -n dev

# Get API Gateway URL
echo -e "${GREEN}=========================================="
echo "Access Information"
echo -e "==========================================${NC}"
echo "To access the API Gateway, run:"
echo "  minikube service api-gateway -n dev"
echo ""
echo "Or use port-forward:"
echo "  kubectl port-forward svc/api-gateway 8080:8080 -n dev"
echo ""
echo "To access Eureka Dashboard:"
echo "  kubectl port-forward svc/service-discovery 8761:8761 -n dev"
echo "  Then open: http://localhost:8761"
echo -e "${GREEN}=========================================="
echo "Deployment completed successfully!"
echo -e "==========================================${NC}"
