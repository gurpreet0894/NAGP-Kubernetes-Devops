#!/bin/bash

# Kubernetes Multi-Tier Architecture Cleanup Script
# This script removes all deployed resources

set -e

echo "=========================================="
echo "Kubernetes Multi-Tier Architecture Cleanup"
echo "=========================================="
echo ""

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

print_warning() {
    echo -e "$1"
}

# Confirm deletion
print_warning "This will delete all resources in the nagp-app namespace."
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""

# Delete HPA
kubectl delete -f k8s/hpa.yaml --ignore-not-found=true

# Delete Ingress
kubectl delete -f k8s/ingress.yaml --ignore-not-found=true

# Delete Service API
kubectl delete -f k8s/api-service.yaml --ignore-not-found=true
kubectl delete -f k8s/api-deployment.yaml --ignore-not-found=true

# Delete Database
kubectl delete -f k8s/database-statefulset.yaml --ignore-not-found=true
kubectl delete -f k8s/database-service.yaml --ignore-not-found=true

# Delete PVC
kubectl delete -f k8s/persistentvolumeclaim.yaml --ignore-not-found=true

# Delete ConfigMaps and Secrets
kubectl delete -f k8s/configmap.yaml --ignore-not-found=true
kubectl delete -f k8s/database-init-configmap.yaml --ignore-not-found=true
kubectl delete -f k8s/secret.yaml --ignore-not-found=true

# Delete Namespace
kubectl delete -f k8s/namespace.yaml --ignore-not-found=true

# Delete Namespace
kubectl delete -f k8s/storageclass.yaml --ignore-not-found=true

# Optionally delete PV
echo ""
read -p "Do you want to delete the PersistentVolume? This will remove all data. (yes/no): " delete_pv

if [ "$delete_pv" = "yes" ]; then
    kubectl delete -f k8s/persistentvolume.yaml --ignore-not-found=true
else
    print_info "PersistentVolume retained. You can delete it manually later with:"
    echo "kubectl delete -f k8s/persistentvolume.yaml"
fi

echo ""
echo "=========================================="
print_success "Cleanup completed!"
echo "=========================================="
