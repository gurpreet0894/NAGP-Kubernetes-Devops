#!/bin/bash

# GKE Deployment Script for NAGP Assignment
# This script deploys the multi-tier architecture to Google Kubernetes Engine

set -e

echo "=========================================="
echo "GKE Multi-Tier Architecture Deployment"
echo "=========================================="
echo ""

# Function to print colored output
print_success() {
    echo -e "$1"
}
print_info() {
    echo -e "$1"
}

print_error() {
    echo -e "$1"
}

print_header() {
    echo -e "$1"
}

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    print_error "gcloud CLI is not installed. Please install gcloud first."
    echo "Visit: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

print_success "kubectl and gcloud are installed"
echo ""

# Display cluster info
print_header "Cluster Information:"
kubectl cluster-info | head -2
echo ""

# Check if nginx ingress controller is installed
print_info "Checking for nginx ingress controller..."
if kubectl get namespace ingress-nginx &> /dev/null; then
    print_success "Nginx ingress controller namespace exists"
    if kubectl get service ingress-nginx-controller -n ingress-nginx &> /dev/null; then
        print_success "Nginx ingress controller is already installed"
    else
        print_info "Installing nginx ingress controller..."
        kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
        print_success "Nginx ingress controller installed"
    fi
else
    print_info "Installing nginx ingress controller..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
    print_success "Nginx ingress controller installed"
fi
echo ""

kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s || {
    print_error "Nginx ingress controller not ready. Checking status..."
    kubectl get pods -n ingress-nginx
}
print_success "Nginx ingress controller is ready"
echo ""

# Get Load Balancer IP for nginx ingress controller
print_info "Getting Load Balancer IP for nginx ingress controller..."
NGINX_LB_IP=$(kubectl get service ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
if [ -z "$NGINX_LB_IP" ]; then
    print_info "Load Balancer IP is being provisioned for nginx ingress controller..."
    echo "This typically takes 2-3 minutes."
else
    print_success "Nginx Ingress Controller Load Balancer IP: $NGINX_LB_IP"
fi
echo ""
kubectl apply -f k8s/storageclass.yaml
echo ""

# Step 1: Create Namespace
kubectl apply -f k8s/namespace.yaml
echo ""

# Step 2: Create ConfigMaps
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/database-init-configmap.yaml
echo ""

# Step 3: Create Secrets
kubectl apply -f k8s/secret.yaml
echo ""

# Step 4: Create PersistentVolumeClaim
kubectl apply -f k8s/persistentvolumeclaim.yaml
echo ""

# Wait for PVC to be bound
print_info "Waiting for PVC to be bound..."
kubectl wait --for=condition=Bound pvc/postgres-pvc -n nagp-app --timeout=60s || {
    print_error "PVC binding timeout. Checking status..."
    kubectl describe pvc postgres-pvc -n nagp-app
}
print_success "PVC is bound"
echo ""

# Step 5: Deploy Database StatefulSet
kubectl apply -f k8s/database-service.yaml
kubectl apply -f k8s/database-statefulset.yaml
echo ""

# Wait for database to be ready
kubectl wait --for=condition=Ready pod/postgres-0 -n nagp-app --timeout=180s || {
    print_error "Database pod not ready. Checking status..."
    kubectl describe pod postgres-0 -n nagp-app
    kubectl logs postgres-0 -n nagp-app
}
echo ""

# Step 6: Deploy Service API
kubectl apply -f k8s/api-deployment.yaml
kubectl apply -f k8s/api-service.yaml
echo ""

# Wait for API pods to be ready
kubectl wait --for=condition=Ready pod -l app=service-api -n nagp-app --timeout=180s || {
    print_error "API pods not ready. Checking status..."
    kubectl get pods -n nagp-app
    kubectl describe deployment service-api -n nagp-app
}
echo ""

# Step 7: Create Ingress (GKE Load Balancer)
kubectl apply -f k8s/ingress.yaml
echo ""
echo "You can check the status with: kubectl get ingress api-ingress -n nagp-app --watch"
echo ""

# Step 8: Create HPA
kubectl apply -f k8s/hpa.yaml
echo ""

# Display deployment status
echo "=========================================="
print_header "Deployment Status"
echo "=========================================="
echo ""
kubectl get all -n nagp-app
echo ""

kubectl get pv,pvc -n nagp-app
echo ""

kubectl get configmap,secret -n nagp-app
echo ""

kubectl get ingress -n nagp-app
echo ""

kubectl get hpa -n nagp-app
echo ""

# Get Load Balancer IP
echo "=========================================="
print_header "Load Balancer Information"
echo "=========================================="
echo ""

LB_IP=$(kubectl get ingress api-ingress -n nagp-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
echo "  curl http://$LB_IP/health"
echo "  curl http://$LB_IP/health/db"
echo "  curl http://$LB_IP/api/employees"

echo ""
echo "=========================================="
print_success "Deployment completed successfully!"
echo "=========================================="
echo ""
