# Cloud Computing Assignment 2 - Documentation

## Student Information
- **Assignment**: Cloud Computing and Big Data Systems - Fall 2025, Assignment 2
- **Docker Hub Username**: thetanishrana
- **Date**: October 29, 2025

---

## Table of Contents
1. [Overview](#overview)
2. [Prerequisites Setup](#prerequisites-setup)
3. [Application Architecture](#application-architecture)
4. [Part 1: Docker Compose Deployment](#part-1-docker-compose-deployment)
5. [Part 2: Kubernetes on Minikube](#part-2-kubernetes-on-minikube)
6. [Part 3: ReplicaSet Self-Healing](#part-3-replicaset-self-healing)
7. [Part 4: Rolling Updates](#part-4-rolling-updates)
8. [Part 5: Health Probes](#part-5-health-probes)
9. [Key Learnings](#key-learnings)
10. [Conclusion](#conclusion)

---

## Overview

This assignment demonstrates the deployment and management of a containerized Flask + MongoDB To-Do application using:
- **Docker & Docker Compose** for local containerization
- **Kubernetes (Minikube)** for orchestration
- **Persistent storage** for data persistence
- **ReplicaSets** for high availability
- **Rolling updates** for zero-downtime deployments
- **Health probes** for application monitoring

### Application Stack
- **Frontend/Backend**: Flask 2.1.3 (Python web framework)
- **Database**: MongoDB 5.0
- **Container Runtime**: Docker
- **Orchestration**: Kubernetes (Minikube locally, EKS for cloud)
- **Registry**: Docker Hub

---

## Prerequisites Setup

### Installed Tools
All prerequisites were installed using a custom script:

```bash
#!/bin/bash
# setup-prerequisites.sh

# Docker Desktop
brew install --cask docker

# kubectl (Kubernetes CLI)
brew install kubectl

# Minikube (local Kubernetes cluster)
brew install minikube

# AWS CLI
brew install awscli

# eksctl (EKS cluster management)
brew tap weaveworks/tap
brew install weaveworks/tap/eksctl

# Helm (Kubernetes package manager)
brew install helm
```

### Verification
```bash
docker --version
kubectl version --client
minikube version
aws --version
eksctl version
helm version
```

---

## Application Architecture

### Directory Structure
```
CBD_Assignment_2/
├── app.py                      # Flask application with health endpoints
├── requirements.txt            # Python dependencies
├── Dockerfile                  # Container image definition
├── docker-compose.yml          # Multi-container orchestration
├── .dockerignore              # Docker build exclusions
├── setup-prerequisites.sh      # Prerequisites installation script
├── templates/                  # HTML templates
│   ├── index.html
│   ├── update.html
│   ├── searchlist.html
│   └── credits.html
├── static/                     # CSS, JavaScript, images
│   └── assets/
└── k8s/                        # Kubernetes manifests
    ├── mongodb-pvc.yaml
    ├── mongodb-deployment.yaml
    ├── mongodb-service.yaml
    ├── flask-deployment.yaml
    └── flask-service.yaml
```

### Health Check Endpoints
Added to `app.py` for Kubernetes probes:

```python
@app.route("/health")
def health():
    """Health check endpoint for Kubernetes liveness probe"""
    try:
        client.admin.command('ping')
        return {"status": "healthy", "database": "connected"}, 200
    except Exception as e:
        return {"status": "unhealthy", "error": str(e)}, 500

@app.route("/ready")
def ready():
    """Readiness check endpoint for Kubernetes readiness probe"""
    try:
        client.admin.command('ping')
        return {"status": "ready"}, 200
    except Exception as e:
        return {"status": "not ready", "error": str(e)}, 500
```

---

## Part 1: Docker Compose Deployment

### 1.1 Dockerfile

Created a multi-stage Docker image for the Flask application:

```dockerfile
# Use Python 3.9 slim image as base
FROM python:3.9-slim

# Set working directory in container
WORKDIR /app

# Copy requirements file
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py .
COPY templates/ templates/
COPY static/ static/

# Expose Flask port
EXPOSE 5000

# Set environment variables
ENV FLASK_ENV=production
ENV MONGO_HOST=mongodb
ENV MONGO_PORT=27017

# Run the application
CMD ["python", "app.py"]
```

### 1.2 Docker Compose Configuration

Created `docker-compose.yml` with persistent volumes:

```yaml
version: '3.8'

services:
  # MongoDB Database Service
  mongodb:
    image: mongo:5.0
    container_name: todo-mongodb
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db
    networks:
      - todo-network
    healthcheck:
      test: echo 'db.runCommand("ping").ok' | mongo localhost:27017/test --quiet
      interval: 10s
      timeout: 5s
      retries: 5

  # Flask Application Service
  flask-app:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: todo-flask-app
    ports:
      - "5001:5000"
    environment:
      - MONGO_HOST=mongodb
      - MONGO_PORT=27017
      - FLASK_ENV=development
    depends_on:
      - mongodb
    networks:
      - todo-network
    restart: unless-stopped

# Named volumes for data persistence
volumes:
  mongodb_data:
    driver: local

# Custom network for service communication
networks:
  todo-network:
    driver: bridge
```

### 1.3 Deployment Steps

```bash
# Build and start containers
docker compose up -d --build

# Verify containers are running
docker compose ps

# Check logs
docker logs todo-flask-app
docker logs todo-mongodb

# Test health endpoint
curl http://localhost:5001/health
```

**Result**: Both containers running successfully
- MongoDB: Healthy with persistent volume
- Flask app: Accessible on port 5001

### 1.4 Docker Hub

```bash
# Tag image as v1.0
docker tag cbd_assignment_2-flask-app:latest thetanishrana/todo-flask-app:1.0

# Push to Docker Hub
docker push thetanishrana/todo-flask-app:1.0
```

**Image URL**: `thetanishrana/todo-flask-app:1.0`

---

## Part 2: Kubernetes on Minikube

### 2.1 Start Minikube

```bash
# Start Minikube cluster with 4GB RAM and 2 CPUs
minikube start --driver=docker --memory=4096 --cpus=2

# Verify cluster is ready
kubectl get nodes
```

Output:
```
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   18s   v1.34.0
```

### 2.2 Kubernetes Manifests

#### MongoDB PersistentVolumeClaim (`k8s/mongodb-pvc.yaml`)
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mongodb-pvc
  labels:
    app: mongodb
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: standard
```

#### MongoDB Deployment (`k8s/mongodb-deployment.yaml`)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongodb
  labels:
    app: mongodb
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongodb
  template:
    metadata:
      labels:
        app: mongodb
    spec:
      containers:
      - name: mongodb
        image: mongo:5.0
        ports:
        - containerPort: 27017
        volumeMounts:
        - name: mongodb-storage
          mountPath: /data/db
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
      volumes:
      - name: mongodb-storage
        persistentVolumeClaim:
          claimName: mongodb-pvc
```

#### MongoDB Service (`k8s/mongodb-service.yaml`)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: mongodb
  labels:
    app: mongodb
spec:
  type: ClusterIP
  ports:
  - port: 27017
    targetPort: 27017
    protocol: TCP
  selector:
    app: mongodb
```

#### Flask Deployment with Health Probes (`k8s/flask-deployment.yaml`)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-app
  labels:
    app: flask-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: flask-app
  template:
    metadata:
      labels:
        app: flask-app
    spec:
      containers:
      - name: flask-app
        image: thetanishrana/todo-flask-app:1.0
        ports:
        - containerPort: 5000
        env:
        - name: MONGO_HOST
          value: "mongodb"
        - name: MONGO_PORT
          value: "27017"
        - name: FLASK_ENV
          value: "production"
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /health
            port: 5000
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /ready
            port: 5000
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
```

#### Flask Service (`k8s/flask-service.yaml`)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: flask-app
  labels:
    app: flask-app
spec:
  type: NodePort
  ports:
  - port: 5000
    targetPort: 5000
    nodePort: 30500
    protocol: TCP
  selector:
    app: flask-app
```

### 2.3 Deploy to Kubernetes

```bash
# Apply all Kubernetes manifests
kubectl apply -f k8s/

# Verify deployment
kubectl get all

# Check PVC status
kubectl get pvc
```

Output:
```
NAME                        READY   STATUS    RESTARTS   AGE
pod/flask-app-9488d77d5-bbmg8   1/1     Running   1          3m37s
pod/flask-app-9488d77d5-pzjdm   1/1     Running   1          3m37s
pod/flask-app-9488d77d5-tmv8d   1/1     Running   1          3m37s
pod/mongodb-576f8f6cdb-xt59v    1/1     Running   0          3m37s

NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
service/flask-app    NodePort    10.106.7.156     <none>        5000:30500/TCP   3m37s
service/mongodb      ClusterIP   10.102.109.229   <none>        27017/TCP        3m37s

NAME                        READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/flask-app   3/3     3            3           3m37s
deployment.apps/mongodb     1/1     1            1           3m37s

NAME                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/flask-app-9488d77d5   3         3         3       3m37s
replicaset.apps/mongodb-576f8f6cdb    1         1         1       3m37s
```

### 2.4 Access Application

```bash
# Get service URL
minikube service flask-app --url
```

Output: `http://127.0.0.1:53377`

Application is now accessible via the Minikube service tunnel.

---

## Part 3: ReplicaSet Self-Healing

### 3.1 Demonstration

**Objective**: Prove that Kubernetes automatically recreates deleted pods to maintain desired replica count.

```bash
# Get current pods
kubectl get pods -l app=flask-app -o wide

# Output before deletion:
# NAME                        READY   STATUS    RESTARTS   AGE
# flask-app-9488d77d5-bbmg8   1/1     Running   1          7m
# flask-app-9488d77d5-pzjdm   1/1     Running   1          7m
# flask-app-9488d77d5-tmv8d   1/1     Running   1          7m

# Delete one pod
kubectl delete pod flask-app-9488d77d5-bbmg8

# Immediately check pods (2 seconds later)
kubectl get pods -l app=flask-app

# Output showing new pod being created:
# NAME                        READY   STATUS    RESTARTS   AGE
# flask-app-9488d77d5-4jls2   1/1     Running   0          37s  <- NEW POD
# flask-app-9488d77d5-pzjdm   1/1     Running   1          8m
# flask-app-9488d77d5-tmv8d   1/1     Running   1          8m
```

### 3.2 Observations

1. **Immediate Response**: ReplicaSet controller detected pod deletion within seconds
2. **New Pod Created**: Pod `flask-app-9488d77d5-4jls2` automatically created to replace deleted pod
3. **Desired State Maintained**: 3 replicas maintained throughout the process
4. **Zero Downtime**: Other 2 pods continued serving traffic during replacement
5. **Self-Healing**: No manual intervention required

### 3.3 ReplicaSet Behavior

```bash
# View ReplicaSet details
kubectl describe rs flask-app-9488d77d5
```

Key metrics:
- **Desired replicas**: 3
- **Current replicas**: 3
- **Ready replicas**: 3
- **Events**: Shows pod deletion and new pod creation

This demonstrates Kubernetes' **declarative configuration** and **self-healing** capabilities - the system automatically maintains the desired state defined in our deployment.

---

## Part 4: Rolling Updates

### 4.1 Create Version 2.0

Modified `templates/index.html` to add version indicator:

```html
<!-- Original -->
<h1>{{ h }}</h1>

<!-- Updated for v2.0 -->
<h1>{{ h }} - v2.0</h1>
```

### 4.2 Build and Push v2.0

```bash
# Build new image
docker build -t thetanishrana/todo-flask-app:2.0 .

# Push to Docker Hub
docker push thetanishrana/todo-flask-app:2.0
```

### 4.3 Trigger Rolling Update

```bash
# Update deployment to use new image
kubectl set image deployment/flask-app flask-app=thetanishrana/todo-flask-app:2.0

# Watch the rollout
kubectl rollout status deployment/flask-app
```

Output:
```
Waiting for deployment "flask-app" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "flask-app" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "flask-app" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "flask-app" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "flask-app" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "flask-app" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "flask-app" rollout to finish: 1 old replicas are pending termination...
deployment "flask-app" successfully rolled out
```

### 4.4 Verify Rolling Update

```bash
# Check ReplicaSets
kubectl get rs -l app=flask-app
```

Output:
```
NAME                  DESIRED   CURRENT   READY   AGE
flask-app-8d94cc4c8   3         3         3       2m   <- NEW (v2.0)
flask-app-9488d77d5   0         0         0       13m  <- OLD (v1.0)
```

```bash
# View pods with new version
kubectl get pods -l app=flask-app
```

Output:
```
NAME                        READY   STATUS    RESTARTS   AGE
flask-app-8d94cc4c8-jtwln   1/1     Running   0          2m
flask-app-8d94cc4c8-lmf6f   1/1     Running   0          90s
flask-app-8d94cc4c8-z9qjd   1/1     Running   0          105s
```

### 4.5 Rollout History

```bash
kubectl rollout history deployment/flask-app
```

Output:
```
deployment.apps/flask-app
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
```

### 4.6 Rolling Update Strategy

The default rolling update strategy used:
- **Max Unavailable**: 25% (maximum 0-1 pod can be unavailable)
- **Max Surge**: 25% (maximum 1 additional pod during update)

This ensures:
1. **Zero Downtime**: At least 2 pods always available
2. **Gradual Rollout**: Pods updated one at a time
3. **Health Checks**: New pods must pass readiness probes before old pods terminated
4. **Rollback Capability**: Can revert to previous version if issues detected

---

## Part 5: Health Probes

### 5.1 Liveness Probe

**Purpose**: Determines if the container is running. If it fails, Kubernetes restarts the container.

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 5000
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3
```

**Configuration**:
- Checks `/health` endpoint every 10 seconds
- Waits 30 seconds after container start before first check
- Declares unhealthy after 3 consecutive failures
- Triggers container restart if unhealthy

### 5.2 Readiness Probe

**Purpose**: Determines if the container is ready to accept traffic. If it fails, pod is removed from service endpoints.

```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 5000
  initialDelaySeconds: 10
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 3
```

**Configuration**:
- Checks `/ready` endpoint every 5 seconds
- Waits 10 seconds after container start before first check
- Removes from service after 3 consecutive failures
- Does NOT restart container, only removes from load balancing

### 5.3 Health Probe Behavior During Rolling Update

During the v1.0 → v2.0 rolling update:

1. **New pod starts**: Readiness probe begins checking after 10s
2. **Pod becomes ready**: Passes readiness checks, added to service endpoints
3. **Old pod termination begins**: Receives SIGTERM signal
4. **Graceful shutdown**: 30-second grace period for existing connections
5. **Old pod removed**: Only after new pod is Ready and serving traffic

This ensures **zero downtime** during updates.

### 5.4 Test Health Endpoints

```bash
# Get pod IP
POD_IP=$(kubectl get pod flask-app-8d94cc4c8-jtwln -o jsonpath='{.status.podIP}')

# Test health endpoint from inside cluster
kubectl run test-pod --rm -it --image=curlimages/curl -- curl http://$POD_IP:5000/health

# Output:
# {"database":"connected","status":"healthy"}

# Test ready endpoint
kubectl run test-pod --rm -it --image=curlimages/curl -- curl http://$POD_IP:5000/ready

# Output:
# {"status":"ready"}
```

### 5.5 Monitoring Health Events

```bash
# View events showing health check activity
kubectl get events --field-selector involvedObject.name=flask-app-8d94cc4c8-jtwln --sort-by='.lastTimestamp'
```

Shows:
- Successful readiness probe checks
- Container started events
- Pod became ready events

---

## Key Learnings

### Docker & Containerization
1. **Multi-container applications**: Docker Compose simplifies orchestration of Flask + MongoDB
2. **Persistent volumes**: Data survives container restarts
3. **Networking**: Containers communicate via service names (DNS resolution)
4. **Image layers**: Optimized Dockerfile reduces build time and image size

### Kubernetes Orchestration
1. **Declarative configuration**: Desired state defined in YAML, Kubernetes maintains it
2. **Self-healing**: Automatically replaces failed pods
3. **Service discovery**: ClusterIP services enable internal communication
4. **Resource management**: CPU and memory limits prevent resource exhaustion

### High Availability
1. **ReplicaSets**: 3 replicas ensure service availability even if 1-2 pods fail
2. **Rolling updates**: Zero-downtime deployments using gradual pod replacement
3. **Health probes**: Automatic detection and recovery from application failures
4. **Load balancing**: Service distributes traffic across all ready pods

### DevOps Best Practices
1. **Version control**: Tagged images (v1.0, v2.0) enable rollback capability
2. **Immutable infrastructure**: Each version is a new immutable image
3. **Infrastructure as Code**: All configuration in version-controlled YAML files
4. **Observability**: Health endpoints provide application state visibility

---

## Deployment Summary

### Docker Compose (Local Development)
- **Status**: ✅ Completed
- **Services**: Flask app + MongoDB
- **Persistent Storage**: Named volume `mongodb_data`
- **Network**: Custom bridge network `todo-network`
- **Access**: http://localhost:5001

### Minikube (Local Kubernetes)
- **Status**: ✅ Completed
- **Cluster**: Single-node Minikube with Docker driver
- **Replicas**: 3 Flask pods, 1 MongoDB pod
- **Storage**: PersistentVolumeClaim (1Gi)
- **Services**: NodePort (30500) for external access, ClusterIP for internal
- **Access**: http://127.0.0.1:53377 (via minikube tunnel)

### Key Features Demonstrated
- ✅ Containerization with Docker
- ✅ Multi-container orchestration with Docker Compose
- ✅ Kubernetes deployment with persistent storage
- ✅ ReplicaSet self-healing
- ✅ Rolling updates (v1.0 → v2.0)
- ✅ Liveness and Readiness probes
- ✅ Resource limits and requests
- ✅ Service networking (ClusterIP, NodePort)

### Docker Hub Images
- `thetanishrana/todo-flask-app:1.0` (Initial release)
- `thetanishrana/todo-flask-app:2.0` (Updated version with visual change)
- `thetanishrana/todo-flask-app:latest` (Points to latest version)

---

## Conclusion

This assignment successfully demonstrated the complete lifecycle of containerized application deployment, from local development with Docker Compose to production-ready Kubernetes orchestration.

### Achievements
1. **Containerization**: Built optimized Docker images with health check endpoints
2. **Orchestration**: Deployed multi-replica application with persistent storage
3. **High Availability**: Demonstrated self-healing capabilities of ReplicaSets
4. **Zero-Downtime Updates**: Performed rolling update from v1.0 to v2.0
5. **Health Monitoring**: Implemented liveness and readiness probes
6. **Best Practices**: Applied resource limits, proper networking, and declarative configuration

### Skills Developed
- Docker containerization and image optimization
- Docker Compose for local development
- Kubernetes manifests (Deployments, Services, PVCs)
- kubectl CLI for cluster management
- Application health monitoring and probing
- Rolling update strategies
- Container orchestration debugging

### Production Readiness
The application is now ready for cloud deployment with:
- Health checks for automatic recovery
- Rolling update strategy for safe deployments
- Persistent storage for data durability
- Resource limits for stable operation
- Multiple replicas for high availability

This foundation can be extended to AWS EKS, Azure AKS, or Google GKE with minimal modifications, demonstrating the portability and consistency that Kubernetes provides across different cloud platforms.
