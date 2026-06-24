# Kubernetes Multi-Tier Architecture on GKE

##  Project Overview

This project demonstrates a **multi-tier architecture** deployed on **Google Kubernetes Engine (GKE)**, featuring a Service API tier (Node.js) and a Database tier (PostgreSQL) with complete DevOps best practices, self-healing capabilities, data persistence, and FinOps optimization.

---

##  Project Links

### Repository & Resources
- GitHub Repository: `https://github.com/gurpreet0894/NAGP-Kubernetes-Devops`
- Docker Hub Image: `https://hub.docker.com/r/gurpreet0894/service-api`
  - Image: `gurpreet0894/service-api:v1`
  - Image: `gurpreet0894/service-api:v2`

### Live API Endpoint
- Service API URL: `http://34.75.28.244/api/employees`

### Video Demonstration
- Screen Recording: `https://drive.google.com/drive/folders/1WOvE4D_1MT6CzORYqFxAKcEQbXFYCab_?usp=sharing`

---

##  Key Features Implemented

###  Kubernetes Objects Deployed

| Object | Name | Purpose | Count |
|--------|------|---------|-------|
| **Namespace** | `nagp-app` | Logical isolation | 1 |
| **ConfigMap** | `db-config` | Database configuration | 1 |
| **ConfigMap** | `postgres-init-script` | DB initialization SQL | 1 |
| **Secret** | `db-secret` | Database credentials | 1 |
| **StorageClass** | `standard-rwo-retain` | Custom storage with Retain policy | 1 |
| **PersistentVolumeClaim** | `postgres-pvc` | Storage claim (1 GB) | 1 |
| **PersistentVolume** | Auto-created | GCE persistent disk | 1 |
| **StatefulSet** | `postgres` | Database tier | 1 pod |
| **Deployment** | `service-api` | API tier | 4 pods |
| **Service** | `postgres-service` | Headless service for DB | 1 |
| **Service** | `service-api` | ClusterIP for API | 1 |
| **Ingress** | `api-ingress` | External access routing | 1 |
| **HPA** | `service-api-hpa` | Auto-scaling (4-10 pods) | 1 |

###  Features

#### 1. **Self-Healing**
- Automatic pod restart on failure
- Liveness and readiness probes
- Deployment ensures desired state

#### 2. **Data Persistence**
- PostgreSQL data survives pod restarts
- PersistentVolume with Retain policy
- GCE persistent disk backend

#### 3. **High Availability**
- 4 API replicas for load distribution
- Rolling update strategy (zero downtime)
- Health checks for traffic routing

#### 4. **Auto-Scaling**
- Horizontal Pod Autoscaler (HPA)
- Scales from 4 to 10 pods based on CPU
- Target: 70% CPU utilization

#### 5. **Security Best Practices**
- Secrets for sensitive data
- Volume mounts instead of Injecting as Environment Variables
- Read-only secret mounts
- Network isolation

#### 6. **FinOps Optimization**
- Resource requests and limits defined
- Right-sized containers
- Cost-effective storage class

---

## Deployment Guide (GKE)

### Prerequisites

1. **Tools Installed**
   ```bash
   # Install gcloud CLI
   
   # Install kubectl
   gcloud components install kubectl
   
   # Verify installations
   gcloud version
   kubectl version --client
   ```

2. **Docker Hub Account**
   - For pushing container images

3. **GKE Cluster already created and connected through gcloud CLI** 
   - For deploying the objects in cluster using CLI

---

### Step 2: Build and Push Docker Image

```bash
git clone https://github.com/gurpreet0894/Nagp-Kubernetes-Devops

cd service-api
docker build -t [Your_Docker_Hub_UserName]/service-api:v1 .

docker login

docker push [Your_Docker_Hub_UserName]/service-api:v1

docker images | grep service-api

cd ..
```

---

### Step 3: Deploy to GKE

```bash
# Make the deployment script executable
chmod +x deploy-gke.sh

# Run the automated deployment script
./deploy-gke.sh
```

The script will automatically:
-  Install nginx ingress controller
-  Create custom StorageClass with Retain policy
-  Create namespace
-  Apply ConfigMaps and Secrets
-  Create PersistentVolumeClaim
-  Deploy PostgreSQL StatefulSet
-  Deploy Service API Deployment
-  Create Services
-  Create Ingress
-  Create HPA

---

### Step 4: Get Load Balancer IP

```bash
kubectl get ingress api-ingress -n nagp-app --watch
```
Once IP is assigned, get it from the output of the above command

---

### Step 5: Test the API

```bash
# Test health endpoint
curl http://[Ip_Fetch_From_Above]/health

# Test database health
curl http://[Ip_Fetch_From_Above]/health/db

# Get all employees
curl http://[Ip_Fetch_From_Above]/api/employees
```

---

## FinOps Considerations

### Resource Optimization

#### Service API Tier
```yaml
resources:
  requests:
    memory: "128Mi"  # Minimum guaranteed
    cpu: "100m"      # 0.1 CPU core
  limits:
    memory: "256Mi"  # Maximum allowed
    cpu: "200m"      # 0.2 CPU core
```

**Cost Impact:**
- 4 pods × 128Mi = 512Mi memory
- 4 pods × 100m = 0.4 CPU cores
- Efficient resource utilization

#### Database Tier
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "200m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

**Cost Impact:**
- 1 pod × 256Mi = 256Mi memory
- 1 pod × 200m = 0.2 CPU cores
- Right-sized for workload

### Storage Optimization
- **Storage Class**: `standard-rwo-retain` (pd-standard)
- **Size**: 1 GB (minimal for demo)
- **Type**: Standard persistent disk (not SSD)
- **Cost**: ~$0.04/month (included in 30 GB free tier)

### Cost Optimization Strategies

1. **Right-Sizing**
   - Resource requests match actual usage
   - Limits prevent resource waste
   - HPA scales based on demand

3. **Storage Efficiency**
   - Minimal storage size (1 GB)
   - Standard disk (not premium SSD)
   - Retain policy for data safety

4. **Auto-Scaling**
   - Scale down during low traffic
   - Scale up during peak hours
   - Min 4, Max 10 pods

---

##  Cleanup

```bash
chmod +x cleanup.sh
./cleanup.sh
```
---

##  Author

- Email: [gurpreet.singh15@nagarro.com]

---

##  License

This project is created for learning purposes.

---
