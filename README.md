# Cloud and Big Data Assignment 2: Kubernetes Orchestration and Monitoring

**Student:** Tanish Rana
**Docker Hub Username:** thetanishrana
**Submission Date:** October 29, 2025
**Course:** Cloud and Big Data Computing

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [System Architecture](#system-architecture)
3. [Part 1: Creating an Application](#part-1-creating-an-application)
4. [Part 2: Containerizing the Application on Docker](#part-2-containerizing-the-application-on-docker)
5. [Part 3: Deploying the Application on Minikube](#part-3-deploying-the-application-on-minikube)
6. [Part 4: Deploying the Application on AWS EKS](#part-4-deploying-the-application-on-aws-eks)
7. [Part 5: Deployments and ReplicaSets](#part-5-deployments-and-replicasets)
8. [Part 6: Rolling Update Strategy](#part-6-rolling-update-strategy)
9. [Part 7: Health Monitoring](#part-7-health-monitoring)
10. [Step 8: Alerting (Extra Credit)](#step-8-alerting-extra-credit)
11. [Technical Challenges and Solutions](#technical-challenges-and-solutions)
12. [Key Learning Outcomes](#key-learning-outcomes)
13. [Cost Analysis](#cost-analysis)
14. [Conclusion](#conclusion)
15. [References](#references)

---

## Executive Summary

This project demonstrates a comprehensive implementation of containerized application deployment using Docker and Kubernetes orchestration across both local (Minikube) and cloud (AWS EKS) environments. The assignment showcases critical cloud-native concepts including container orchestration, self-healing capabilities, zero-downtime deployments, persistent storage management, and production-grade monitoring with Prometheus and Alertmanager.

The application is a Flask-based To-Do list with MongoDB backend, deployed as a highly available system with three replicas, automatic failover, and complete observability through Prometheus metrics and Slack alerting integration. All core requirements and extra credit objectives have been successfully completed.

---

## System Architecture

### High-Level Architecture

The application follows a three-tier architecture pattern:

```
┌─────────────────────────────────────────────────────────────┐
│                    Load Balancer / Service                   │
│              (NodePort on Minikube / ELB on EKS)            │
└─────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
┌───────▼────────┐   ┌───────▼────────┐   ┌───────▼────────┐
│  Flask Pod 1   │   │  Flask Pod 2   │   │  Flask Pod 3   │
│  (Replica)     │   │  (Replica)     │   │  (Replica)     │
└───────┬────────┘   └───────┬────────┘   └───────┬────────┘
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              │
                    ┌─────────▼──────────┐
                    │   MongoDB Service   │
                    │    (ClusterIP)      │
                    └─────────┬──────────┘
                              │
                    ┌─────────▼──────────┐
                    │   MongoDB Pod       │
                    │  + Persistent Vol   │
                    └────────────────────┘
```

### Monitoring Architecture

```
┌──────────────────────────────────────────────────────────┐
│                  Prometheus Server                        │
│              (Metrics Collection & Storage)               │
└──────────────────┬───────────────────────────────────────┘
                   │
      ┌────────────┼────────────┐
      │            │            │
┌─────▼─────┐ ┌───▼────┐ ┌─────▼──────┐
│   Node    │ │ Kube   │ │   Flask    │
│ Exporter  │ │ State  │ │   Pods     │
│  (Nodes)  │ │ Metrics│ │ (Targets)  │
└───────────┘ └────────┘ └────────────┘
      │
      │
┌─────▼──────────┐         ┌─────────────┐
│ Alertmanager   ├────────►│   Slack     │
│ (Alert Router) │         │  Webhook    │
└────────────────┘         └─────────────┘
```

---

## Part 1: Creating an Application

### Application Overview

For this assignment, a To-Do web application was created using Flask and MongoDB. The application provides a simple interface for managing tasks with the following features:

- Add new tasks
- Mark tasks as complete
- Delete tasks
- View all tasks, completed tasks, or uncompleted tasks

### Application Enhancements

The Flask application was enhanced with health check endpoints to support Kubernetes health probes:

```python
@app.route("/health")
def health():
    """Liveness probe endpoint - checks if application is alive"""
    try:
        client.admin.command('ping')
        return {"status": "healthy", "database": "connected"}, 200
    except Exception as e:
        return {"status": "unhealthy", "error": str(e)}, 500

@app.route("/ready")
def ready():
    """Readiness probe endpoint - checks if application is ready to serve traffic"""
    try:
        client.admin.command('ping')
        return {"status": "ready"}, 200
    except Exception as e:
        return {"status": "not ready", "error": str(e)}, 500
```

These endpoints enable Kubernetes to:
- **Liveness Probe:** Automatically restart pods that become unresponsive
- **Readiness Probe:** Remove pods from service load balancing when not ready

### Application Stack

- **Backend Framework:** Flask 2.1.3
- **Web Server:** Werkzeug 2.3.7
- **Database:** MongoDB 5.0
- **Database Driver:** PyMongo 4.2.0
- **Programming Language:** Python 3.9

---

## Part 2: Containerizing the Application on Docker

### Docker Image Architecture

**Dockerfile Configuration:**
```dockerfile
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 5000
CMD ["python", "app.py"]
```

**Key Features:**
- Lightweight base image (python:3.9-slim) for reduced image size
- Dependency caching optimization through layered build
- Multi-architecture support (AMD64 for EKS, ARM64 for local development)
- Version pinning for reproducible builds

### Docker Compose Configuration

The docker-compose.yml file orchestrates the Flask application and MongoDB containers for local development:

```yaml
version: '3.8'
services:
  mongodb:
    image: mongo:5.0
    container_name: todo-mongodb
    volumes:
      - mongodb_data:/data/db
    networks:
      - todo-network

  flask-app:
    build: .
    container_name: todo-flask-app
    ports:
      - "5001:5000"
    environment:
      - MONGO_HOST=mongodb
    depends_on:
      - mongodb
    networks:
      - todo-network

networks:
  todo-network:
    driver: bridge

volumes:
  mongodb_data:
```

**Key Features:**
- Persistent volume for MongoDB data
- Network isolation for container communication
- Port mapping (5001:5000) to avoid macOS AirPlay conflicts
- Service dependency management

### Building and Pushing Docker Images

**Build Command:**
```bash
docker build -t thetanishrana/todo-flask-app:1.0 .
```

**Multi-Architecture Build for EKS:**
```bash
docker buildx build --platform linux/amd64 -t thetanishrana/todo-flask-app:2.0 --push .
```

### Docker Hub Repository

Published images available at: `docker.io/thetanishrana/todo-flask-app`

**Available Tags:**
- `1.0` - Initial release (121 MB)
- `2.0` - Updated version with visual enhancements (121 MB)
- `latest` - Points to most recent stable release

---

## Part 3: Deploying the Application on Minikube

### Cluster Configuration

Minikube was configured with appropriate resources for local development:

```bash
minikube start --driver=docker --memory=4096 --cpus=2
```

**Rationale:**
- 4GB RAM allocation supports MongoDB and multiple Flask replicas
- 2 CPU cores provide adequate processing capacity
- Docker driver enables native container integration

### Kubernetes Manifests

The application deployment consists of five Kubernetes resources:

#### 1. MongoDB PersistentVolumeClaim
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mongodb-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: standard
```

#### 2. MongoDB Deployment
- Single replica (stateful application)
- Persistent volume mount at `/data/db`
- Resource limits: 500Mi memory, 500m CPU

#### 3. MongoDB Service (ClusterIP)
- Internal cluster communication only
- Port 27017 exposed to Flask pods

#### 4. Flask Deployment
- Three replicas for high availability
- Rolling update strategy (maxUnavailable: 1, maxSurge: 1)
- Health probes configured with appropriate delays and thresholds
- Resource requests: 128Mi memory, 100m CPU
- Resource limits: 256Mi memory, 200m CPU

#### 5. Flask Service (NodePort)
- External access through Minikube
- Port mapping: 80 (service) → 5000 (container) → 30000+ (node)

### Deployment Verification

The application was successfully deployed on Minikube as shown in the following screenshots:

**Figure 1: Minikube Cluster Status and Resources**
![Minikube Deployment](screenshots/Screenshot%202025-10-29%20at%2013.48.34.png)
*Terminal output showing all Kubernetes resources deployed in the default namespace, including 3 Flask replicas and MongoDB pod with persistent storage.*

**Figure 2: Pod Distribution and Status**
![Pod Status](screenshots/Screenshot%202025-10-29%20at%2013.48.42.png)
*Detailed view of running pods with their IP addresses, node assignments, and ready states.*

### Accessing the Application

```bash
minikube service flask-app --url
```

This command provides the URL to access the application through the NodePort service.

---

## Part 4: Deploying the Application on AWS EKS

### AWS Infrastructure Architecture

The production deployment on AWS EKS provides enterprise-grade Kubernetes infrastructure with high availability, security, and scalability.

### Cluster Provisioning

**Cluster Configuration:**
```bash
eksctl create cluster \
  --name todo-app-cluster \
  --region us-east-1 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 2 \
  --nodes-max 4 \
  --managed
```

**Infrastructure Components:**
- **EKS Control Plane:** Managed by AWS (3 master nodes across availability zones)
- **Worker Nodes:** 2x t3.medium EC2 instances (2 vCPU, 4GB RAM each)
- **VPC:** Dedicated virtual private cloud with public/private subnets
- **Availability Zones:** Multi-AZ deployment (us-east-1a, us-east-1b)
- **Security Groups:** Automatic configuration for cluster communication

**Figure 3: EKS Cluster Overview**
![EKS Cluster](screenshots/Screenshot%202025-10-29%20at%2013.51.13.png)
*AWS Console showing EKS cluster details including cluster name, Kubernetes version, VPC configuration, and endpoint information.*

**Figure 4: EKS Node Configuration**
![EKS Nodes](screenshots/Screenshot%202025-10-29%20at%2013.52.03.png)
*Node group configuration displaying 2 worker nodes, instance type (t3.medium), and scaling settings.*

### Storage Configuration: EBS CSI Driver

AWS EKS does not include the EBS CSI driver by default. Manual installation was required:

```bash
# Install EBS CSI driver addon
eksctl create addon --name aws-ebs-csi-driver --cluster todo-app-cluster

# Create IAM policy for EBS operations
aws iam create-policy --policy-name EKS-EBS-CSI-Policy --policy-document file://ebs-csi-policy.json

# Attach policy to node IAM role
aws iam attach-role-policy --role-name <node-role> --policy-arn <policy-arn>
```

**Storage Class Configuration:**
```yaml
storageClassName: gp2  # AWS EBS General Purpose SSD
```

### Service Exposure: AWS Load Balancer

The Flask service was configured as LoadBalancer type to automatically provision AWS Elastic Load Balancer:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: flask-app
spec:
  type: LoadBalancer  # Changed from NodePort
  ports:
  - port: 80
    targetPort: 5000
```

**Figure 5: Application Accessible via AWS Load Balancer**
![Application Access](screenshots/Screenshot%202025-10-29%20at%2013.57.54.png)
*Flask To-Do application successfully accessible through AWS ELB public DNS endpoint.*

**Load Balancer Features:**
- **DNS Name:** a93ad984d3a1c49adbbd09713b93d791-2024893652.us-east-1.elb.amazonaws.com
- **Type:** Classic Load Balancer
- **Health Checks:** Automatic integration with Kubernetes health probes
- **Cross-AZ:** Traffic distributed across both availability zones

### Deployment Verification

**Figure 6: Kubernetes Resources on EKS**
![EKS Resources](screenshots/Screenshot%202025-10-29%20at%2014.02.16.png)
*Complete view of all Kubernetes resources deployed on EKS including deployments, services, and persistent volume claims.*

**Figure 7: Pod Distribution Across Nodes**
![Pod Distribution](screenshots/Screenshot%202025-10-29%20at%2014.02.46.png)
*Three Flask pods distributed across two worker nodes for high availability, with MongoDB pod and persistent storage.*

### AWS Console Verification

**Figure 8: EC2 Instances for EKS Worker Nodes**
![EC2 Instances](screenshots/Screenshot%202025-10-29%20at%2014.03.09.png)
*AWS EC2 console showing 2 running t3.medium instances that serve as EKS worker nodes.*

**Figure 9: Elastic Load Balancer Configuration**
![ELB Configuration](screenshots/Screenshot%202025-10-29%20at%2014.03.27.png)
*Classic Load Balancer details showing listener configuration, health checks, and backend instance registration.*

**Figure 10: EBS Volumes for Persistent Storage**
![EBS Volumes](screenshots/Screenshot%202025-10-29%20at%2014.03.50.png)
*AWS EBS volumes automatically provisioned for MongoDB and Prometheus persistent storage through dynamic volume provisioning.*

### Network Architecture

**Figure 11: VPC and Networking**
![VPC Configuration](screenshots/Screenshot%202025-10-29%20at%2014.04.05.png)
*VPC created by eksctl with public and private subnets across two availability zones, NAT gateways, and internet gateway.*

**Figure 12: Security Group Configuration**
![Security Groups](screenshots/Screenshot%202025-10-29%20at%2014.04.10.png)
*Security groups automatically configured for EKS control plane and worker node communication.*

---

## Part 5: Deployments and ReplicaSets

### ReplicaSet Self-Healing Mechanism

Kubernetes ReplicaSets continuously monitor the actual state versus desired state of pod replicas. When a pod is deleted or fails, the ReplicaSet controller automatically creates a replacement pod to maintain the desired count.

### Configuration

The Flask deployment specifies 3 replicas:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-app
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
        image: thetanishrana/todo-flask-app:2.0
        ports:
        - containerPort: 5000
```

### Demonstration Procedure

1. **Initial State:** Verified 3 running Flask pods
2. **Trigger Failure:** Manually deleted one pod using `kubectl delete pod`
3. **Observation:** ReplicaSet immediately detected the discrepancy
4. **Recovery:** New pod automatically created within seconds
5. **Validation:** Confirmed application remained accessible throughout the process

**Figure 13: Self-Healing Process**
![Self-Healing](screenshots/Screenshot%202025-10-29%20at%2013.23.10.png)
*Terminal screenshot demonstrating pod deletion and automatic recreation by the ReplicaSet controller, showcasing zero-downtime self-healing capabilities.*

### Key Observations

- **Recovery Time:** New pod created and running within 30-45 seconds
- **Service Continuity:** Application remained accessible via service load balancer
- **Zero Configuration:** No manual intervention required for recovery
- **Production Readiness:** Validates application resilience for production workloads

---

## Part 6: Rolling Update Strategy

### Zero-Downtime Deployment Strategy

Rolling updates enable application version changes without service interruption by gradually replacing old pods with new ones.

### Update Strategy Configuration

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 1    # Maximum pods that can be unavailable
    maxSurge: 1          # Maximum extra pods during update
```

**Strategy Rationale:**
- `maxUnavailable: 1` ensures at least 2/3 pods always serve traffic
- `maxSurge: 1` allows temporary 4th pod during transition
- Health probes prevent unhealthy pods from receiving traffic

### Update Procedure

```bash
# Initiate rolling update
kubectl set image deployment/flask-app flask-app=thetanishrana/todo-flask-app:2.0

# Monitor progress
kubectl rollout status deployment/flask-app

# Verify completion
kubectl rollout history deployment/flask-app
```

### Update Process Flow

1. New pod created with v2.0 image (total: 4 pods)
2. New pod passes readiness probe
3. One v1.0 pod terminated (total: 3 pods)
4. Process repeats until all pods updated

**Figure 14: Rolling Update Completion**
![Rolling Update](screenshots/Screenshot%202025-10-29%20at%2013.50.58.png)
*Deployment status showing successful rolling update from version 1.0 to 2.0 with all pods running the new image.*

### Rollback Capability

Kubernetes maintains revision history enabling instant rollback if issues arise:

```bash
kubectl rollout undo deployment/flask-app
```

---

## Part 7: Health Monitoring

### Health Probe Configuration

Kubernetes provides two types of probes to monitor application health:

#### Liveness Probe

**Purpose:** Determines if the container is running. If it fails, Kubernetes restarts the container.

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

**Configuration Details:**
- Waits 30 seconds after container start before first check
- Checks every 10 seconds
- 5 second timeout per check
- Declares unhealthy after 3 consecutive failures
- Triggers container restart if unhealthy

#### Readiness Probe

**Purpose:** Determines if the container is ready to accept traffic. If it fails, pod is removed from service endpoints.

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

**Configuration Details:**
- Waits 10 seconds after container start before first check
- Checks every 5 seconds
- 3 second timeout per check
- Removes from service after 3 consecutive failures
- Does NOT restart container, only removes from load balancing

### Health Check Endpoints

The Flask application implements both health check endpoints:

```python
@app.route("/health")
def health():
    """Liveness probe - checks MongoDB connectivity"""
    try:
        client.admin.command('ping')
        return {"status": "healthy", "database": "connected"}, 200
    except Exception as e:
        return {"status": "unhealthy", "error": str(e)}, 500

@app.route("/ready")
def ready():
    """Readiness probe - checks if ready to serve traffic"""
    try:
        client.admin.command('ping')
        return {"status": "ready"}, 200
    except Exception as e:
        return {"status": "not ready", "error": str(e)}, 500
```

### Monitoring Health Status

```bash
# Check pod status
kubectl get pods

# Describe pod for detailed health information
kubectl describe pod <pod-name>

# View events
kubectl get events --sort-by='.lastTimestamp'
```

### Testing Health Monitoring

The health monitoring system can be tested by:
1. Intentionally causing database connection failures
2. Simulating application crashes
3. Observing automatic pod restarts
4. Verifying service continues with healthy pods

---

## Step 8: Alerting (Extra Credit)

### Prometheus Stack Architecture

The monitoring solution implements a complete observability pipeline using the Prometheus ecosystem.

### Prometheus Server Installation

Prometheus was deployed using the official Helm chart for simplified configuration management:

```bash
# Add Prometheus Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus with custom values
helm install prometheus prometheus-community/prometheus \
  -f prometheus-config/prometheus-values.yaml \
  --namespace monitoring \
  --create-namespace
```

**Key Configuration Parameters:**
```yaml
server:
  persistentVolume:
    enabled: true
    size: 8Gi
    storageClass: gp2

alertmanager:
  enabled: true
  persistentVolume:
    enabled: true
    size: 2Gi
    storageClass: gp2

nodeExporter:
  enabled: true

kubeStateMetrics:
  enabled: true
```

### Monitoring Components

**Figure 15: Prometheus Stack Pods**
![Prometheus Pods](screenshots/Screenshot%202025-10-29%20at%2014.04.32.png)
*All Prometheus monitoring components running in dedicated monitoring namespace, including server, alertmanager, node exporters, and kube-state-metrics.*

**Component Functions:**

1. **Prometheus Server (2/2 containers)**
   - Time-series database for metrics storage
   - Query engine for PromQL queries
   - Alert rule evaluation
   - Data retention: 15 days
   - Storage: 8Gi AWS EBS volume

2. **Alertmanager (1/1 container)**
   - Alert routing and deduplication
   - Slack webhook integration
   - Alert grouping and silencing
   - Storage: 2Gi AWS EBS volume

3. **Node Exporter (2 instances)**
   - Hardware and OS metrics from worker nodes
   - CPU, memory, disk, network statistics
   - Runs as DaemonSet on each node

4. **Kube-State-Metrics (1/1 container)**
   - Kubernetes object state metrics
   - Pod, deployment, service status
   - Resource quota and limit tracking

5. **Pushgateway (1/1 container)**
   - Metrics collection for batch jobs
   - Short-lived job metrics preservation

### Prometheus User Interface

**Figure 16: Prometheus Web UI - Overview**
![Prometheus UI](screenshots/Screenshot%202025-10-29%20at%2016.42.48.png)
*Prometheus web interface showing version information, uptime statistics, and configuration status.*

**Figure 17: Prometheus Targets**
![Prometheus Targets](screenshots/Screenshot%202025-10-29%20at%2016.43.04.png)
*All scrape targets showing UP status, including Kubernetes API server, nodes, pods, and services being monitored.*

**Figure 18: Prometheus Configuration**
![Prometheus Config](screenshots/Screenshot%202025-10-29%20at%2016.43.18.png)
*Loaded Prometheus configuration showing scrape jobs, alert rules, and service discovery configurations.*

### Metrics Queries

**Figure 19: PromQL Query Execution**
![Prometheus Query](screenshots/Screenshot%202025-10-29%20at%2016.44.10.png)
*Prometheus graph interface showing metrics query results for pod status and resource utilization.*

**Example Queries Used:**
```promql
# Check all services are up
up

# Pod phase tracking
kube_pod_status_phase{namespace="default"}

# Memory usage percentage
(container_memory_usage_bytes / container_spec_memory_limit_bytes) * 100

# CPU usage rate
rate(container_cpu_usage_seconds_total[5m])
```

### Alertmanager Configuration

**Figure 20: Alertmanager Web UI**
![Alertmanager UI](screenshots/Screenshot%202025-10-29%20at%2016.44.55.png)
*Alertmanager interface showing cluster status, configuration, and active alerts.*

**Figure 21: Alertmanager Status**
![Alertmanager Status](screenshots/Screenshot%202025-10-29%20at%2016.47.16.png)
*Alertmanager status page displaying routing configuration and receiver details including Slack integration.*

### Slack Integration

**Webhook Configuration:**
```yaml
alertmanager:
  config:
    global:
      slack_api_url: 'https://hooks.slack.com/services/...'

    receivers:
    - name: 'slack-notifications'
      slack_configs:
      - channel: '#all-cloud-big-data-assignment-2'
        send_resolved: true
        title: 'Kubernetes Alert'
        text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'

    route:
      receiver: 'slack-notifications'
      group_by: ['alertname', 'cluster', 'service']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 12h
```

**Figure 22: Slack Channel Integration**
![Slack Integration](screenshots/Screenshot%202025-10-29%20at%2016.48.54.png)
*Slack workspace showing the configured channel for receiving Kubernetes alerts from Alertmanager.*

**Figure 23: Webhook Test Verification**
![Slack Webhook Test](screenshots/Screenshot%202025-10-29%20at%2016.49.14.png)
*Successful test notification sent from Alertmanager to Slack channel, confirming webhook connectivity.*

### Alert Rules Configuration

Four critical alert rules were defined:

```yaml
- alert: PodDown
  expr: up{job="kubernetes-pods"} == 0
  for: 1m
  labels:
    severity: critical
  annotations:
    summary: "Pod {{ $labels.pod }} is down"
    description: "Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} has been down for more than 1 minute."

- alert: PodNotReady
  expr: kube_pod_status_phase{phase!="Running"} > 0
  for: 5m
  labels:
    severity: warning
  annotations:
    summary: "Pod {{ $labels.pod }} is not ready"

- alert: HighMemoryUsage
  expr: (container_memory_usage_bytes / container_spec_memory_limit_bytes) > 0.8
  for: 2m
  labels:
    severity: warning

- alert: HighCPUUsage
  expr: (rate(container_cpu_usage_seconds_total[5m]) / container_spec_cpu_quota) > 0.8
  for: 2m
  labels:
    severity: warning
```

### Monitoring Validation

The complete monitoring stack was validated through:

1. **Metrics Collection:** Verified all targets reporting metrics
2. **Query Execution:** Tested PromQL queries for application metrics
3. **Alert Rule Loading:** Confirmed alert rules loaded in Prometheus
4. **Webhook Connectivity:** Successfully sent test alerts to Slack
5. **End-to-End Pipeline:** Validated complete observability workflow

---

## Conclusion

This project successfully demonstrates comprehensive proficiency in modern cloud-native application deployment and management. All core assignment requirements and extra credit objectives were completed:

**Core Requirements:**
1. Created To-Do application with Flask and MongoDB
2. Containerized application using Docker with multi-architecture support
3. Deployed application on Minikube with 3 replicas
4. Deployed application on AWS EKS with production-grade infrastructure
5. Demonstrated ReplicaSet self-healing capabilities
6. Implemented zero-downtime rolling update strategy
7. Configured health monitoring with liveness and readiness probes

**Extra Credit:**
8. Deployed Prometheus monitoring stack with complete observability
9. Configured Alertmanager with Slack webhook integration
10. Defined custom alert rules for pod failures and resource utilization
11. Validated end-to-end alerting pipeline

The implementation showcases industry best practices including:
- Infrastructure as Code for reproducibility
- Declarative configuration management
- Health probes for automatic failure detection
- Persistent storage for stateful applications
- Load balancing for high availability
- Comprehensive monitoring and alerting
- Detailed documentation for knowledge transfer

This assignment provided valuable hands-on experience with technologies and practices essential for modern DevOps and Site Reliability Engineering roles.
