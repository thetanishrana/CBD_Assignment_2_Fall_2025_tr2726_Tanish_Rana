# Cloud and Big Data Assignment 2: Kubernetes Orchestration and Monitoring

**Student:** Tanish Rana
**Docker Hub Username:** thetanishrana
**Submission Date:** October 29, 2025
**Course:** Cloud and Big Data Computing

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Assignment Objectives](#assignment-objectives)
3. [System Architecture](#system-architecture)
4. [Technology Stack](#technology-stack)
5. [Implementation Overview](#implementation-overview)
6. [Part 1-3: Application Development and Containerization](#part-1-3-application-development-and-containerization)
7. [Part 4: Local Kubernetes Deployment (Minikube)](#part-4-local-kubernetes-deployment-minikube)
8. [Part 5: Self-Healing Demonstration](#part-5-self-healing-demonstration)
9. [Part 6: Rolling Update Implementation](#part-6-rolling-update-implementation)
10. [Part 7: Documentation](#part-7-documentation)
11. [Part 10: AWS EKS Production Deployment](#part-10-aws-eks-production-deployment)
12. [Part 11: Monitoring and Alerting (Extra Credit)](#part-11-monitoring-and-alerting-extra-credit)
13. [Technical Challenges and Solutions](#technical-challenges-and-solutions)
14. [Key Learning Outcomes](#key-learning-outcomes)
15. [Cost Analysis](#cost-analysis)
16. [Conclusion](#conclusion)
17. [References](#references)

---

## Executive Summary

This project demonstrates a comprehensive implementation of containerized application deployment using Docker and Kubernetes orchestration across both local (Minikube) and cloud (AWS EKS) environments. The assignment showcases critical cloud-native concepts including container orchestration, self-healing capabilities, zero-downtime deployments, persistent storage management, and production-grade monitoring with Prometheus and Alertmanager.

The application is a Flask-based To-Do list with MongoDB backend, deployed as a highly available system with three replicas, automatic failover, and complete observability through Prometheus metrics and Slack alerting integration. All core requirements and extra credit objectives have been successfully completed.

---

## Assignment Objectives

### Core Requirements (Parts 1-7)
1. Develop a containerized web application with persistent data storage
2. Create Docker images and publish to Docker Hub registry
3. Deploy application on local Kubernetes cluster using Minikube
4. Demonstrate ReplicaSet self-healing capabilities
5. Implement zero-downtime rolling updates between versions
6. Deploy identical infrastructure on AWS Elastic Kubernetes Service (EKS)
7. Provide comprehensive technical documentation

### Extra Credit Requirements (Part 11)
8. Implement Prometheus monitoring stack for metrics collection
9. Configure Alertmanager with Slack webhook integration
10. Define alert rules for pod failures and resource utilization
11. Demonstrate end-to-end observability pipeline

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

## Technology Stack

### Application Layer
- **Backend Framework:** Flask 2.1.3
- **Web Server:** Werkzeug 2.3.7
- **Database:** MongoDB 5.0
- **Database Driver:** PyMongo 4.2.0
- **Programming Language:** Python 3.9

### Containerization
- **Container Runtime:** Docker 24.x
- **Image Registry:** Docker Hub
- **Orchestration Tool:** Docker Compose (local development)

### Kubernetes Infrastructure
- **Local Environment:** Minikube 1.32.x with Docker driver
- **Cloud Environment:** AWS EKS (Kubernetes 1.28)
- **Node Configuration:** 2x t3.medium EC2 instances
- **Storage:** AWS EBS with gp2 storage class

### Monitoring and Observability
- **Metrics System:** Prometheus 3.7.2
- **Alert Management:** Alertmanager 0.28.1
- **Node Metrics:** Prometheus Node Exporter
- **Cluster Metrics:** Kube-state-metrics
- **Package Manager:** Helm 3.x
- **Alert Destination:** Slack workspace integration

### Cloud Services
- **Cloud Provider:** Amazon Web Services (AWS)
- **Kubernetes Service:** Elastic Kubernetes Service (EKS)
- **Load Balancer:** AWS Elastic Load Balancer (Classic)
- **Storage:** AWS Elastic Block Store (EBS)
- **Networking:** AWS VPC with public/private subnets
- **CLI Tools:** eksctl, AWS CLI v2

---

## Implementation Overview

The project implementation followed a systematic approach:

1. **Application Development:** Enhanced the Flask application with health check endpoints required for Kubernetes liveness and readiness probes.

2. **Containerization:** Created optimized Docker images with proper dependency management and published multiple versions to Docker Hub.

3. **Local Deployment:** Validated Kubernetes manifests and application behavior on Minikube before cloud deployment.

4. **Production Deployment:** Provisioned production-grade AWS EKS cluster with appropriate security, networking, and storage configurations.

5. **Monitoring Integration:** Deployed comprehensive Prometheus stack with custom alert rules and Slack notification pipeline.

---

## Part 1-3: Application Development and Containerization

### Application Enhancements

The Flask To-Do application was enhanced with health check endpoints to support Kubernetes health probes:

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

### Docker Hub Repository

Published images available at: `docker.io/thetanishrana/todo-flask-app`

**Available Tags:**
- `1.0` - Initial release (121 MB)
- `2.0` - Updated version with visual enhancements (121 MB)
- `latest` - Points to most recent stable release

**Multi-Architecture Build Command:**
```bash
docker buildx build --platform linux/amd64 -t thetanishrana/todo-flask-app:2.0 --push .
```

---

## Part 4: Local Kubernetes Deployment (Minikube)

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

---

## Part 5: Self-Healing Demonstration

### ReplicaSet Self-Healing Mechanism

Kubernetes ReplicaSets continuously monitor the actual state versus desired state of pod replicas. When a pod is deleted or fails, the ReplicaSet controller automatically creates a replacement pod to maintain the desired count.

### Demonstration Procedure

1. **Initial State:** Verified 3 running Flask pods
2. **Trigger Failure:** Manually deleted one pod using `kubectl delete pod`
3. **Observation:** ReplicaSet immediately detected the discrepancy
4. **Recovery:** New pod automatically created within seconds
5. **Validation:** Confirmed application remained accessible throughout the process

**Figure 3: Self-Healing Process**
![Self-Healing](screenshots/Screenshot%202025-10-29%20at%2013.23.10.png)
*Terminal screenshot demonstrating pod deletion and automatic recreation by the ReplicaSet controller, showcasing zero-downtime self-healing capabilities.*

### Key Observations

- **Recovery Time:** New pod created and running within 30-45 seconds
- **Service Continuity:** Application remained accessible via service load balancer
- **Zero Configuration:** No manual intervention required for recovery
- **Production Readiness:** Validates application resilience for production workloads

---

## Part 6: Rolling Update Implementation

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

**Figure 4: Rolling Update Completion**
![Rolling Update](screenshots/Screenshot%202025-10-29%20at%2013.50.58.png)
*Deployment status showing successful rolling update from version 1.0 to 2.0 with all pods running the new image.*

### Rollback Capability

Kubernetes maintains revision history enabling instant rollback if issues arise:

```bash
kubectl rollout undo deployment/flask-app
```

---

## Part 7: Documentation

Comprehensive technical documentation was created covering all aspects of the project:

### Documentation Artifacts

1. **[ASSIGNMENT_DOCUMENTATION.md](documentation/ASSIGNMENT_DOCUMENTATION.md)** (21 KB)
   - Detailed setup procedures
   - Architecture diagrams and explanations
   - Step-by-step deployment guides
   - Troubleshooting procedures
   - Best practices and recommendations

2. **[EKS_DEPLOYMENT_GUIDE.md](documentation/EKS_DEPLOYMENT_GUIDE.md)** (48 KB)
   - AWS EKS cluster provisioning
   - IAM role and policy configurations
   - EBS CSI driver installation
   - Load balancer setup
   - Comprehensive troubleshooting guide

3. **[ASSIGNMENT_COMPLETION_SUMMARY.md](documentation/ASSIGNMENT_COMPLETION_SUMMARY.md)**
   - Complete feature checklist
   - Screenshot catalog with descriptions
   - Cost analysis and breakdown
   - Cleanup procedures

4. **[VERIFICATION_COMMANDS.md](documentation/VERIFICATION_COMMANDS.md)**
   - Quick reference commands for testing
   - Deployment verification steps

5. **[SLACK_SETUP.md](documentation/SLACK_SETUP.md)**
   - Slack webhook configuration guide
   - Alertmanager integration setup

6. **README.md** (this document)
   - Academic presentation of work
   - Complete project overview
   - References to all evidence

---

## Part 10: AWS EKS Production Deployment

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

**Figure 5: EKS Cluster Overview**
![EKS Cluster](screenshots/Screenshot%202025-10-29%20at%2013.51.13.png)
*AWS Console showing EKS cluster details including cluster name, Kubernetes version, VPC configuration, and endpoint information.*

**Figure 6: EKS Node Configuration**
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

**Figure 7: Application Accessible via AWS Load Balancer**
![Application Access](screenshots/Screenshot%202025-10-29%20at%2013.57.54.png)
*Flask To-Do application successfully accessible through AWS ELB public DNS endpoint.*

**Load Balancer Features:**
- **DNS Name:** a93ad984d3a1c49adbbd09713b93d791-2024893652.us-east-1.elb.amazonaws.com
- **Type:** Classic Load Balancer
- **Health Checks:** Automatic integration with Kubernetes health probes
- **Cross-AZ:** Traffic distributed across both availability zones

### Deployment Verification

**Figure 8: Kubernetes Resources on EKS**
![EKS Resources](screenshots/Screenshot%202025-10-29%20at%2014.02.16.png)
*Complete view of all Kubernetes resources deployed on EKS including deployments, services, and persistent volume claims.*

**Figure 9: Pod Distribution Across Nodes**
![Pod Distribution](screenshots/Screenshot%202025-10-29%20at%2014.02.46.png)
*Three Flask pods distributed across two worker nodes for high availability, with MongoDB pod and persistent storage.*

### AWS Console Verification

**Figure 10: EC2 Instances for EKS Worker Nodes**
![EC2 Instances](screenshots/Screenshot%202025-10-29%20at%2014.03.09.png)
*AWS EC2 console showing 2 running t3.medium instances that serve as EKS worker nodes.*

**Figure 11: Elastic Load Balancer Configuration**
![ELB Configuration](screenshots/Screenshot%202025-10-29%20at%2014.03.27.png)
*Classic Load Balancer details showing listener configuration, health checks, and backend instance registration.*

**Figure 12: EBS Volumes for Persistent Storage**
![EBS Volumes](screenshots/Screenshot%202025-10-29%20at%2014.03.50.png)
*AWS EBS volumes automatically provisioned for MongoDB and Prometheus persistent storage through dynamic volume provisioning.*

### Network Architecture

**Figure 13: VPC and Networking**
![VPC Configuration](screenshots/Screenshot%202025-10-29%20at%2014.04.05.png)
*VPC created by eksctl with public and private subnets across two availability zones, NAT gateways, and internet gateway.*

**Figure 14: Security Group Configuration**
![Security Groups](screenshots/Screenshot%202025-10-29%20at%2014.04.10.png)
*Security groups automatically configured for EKS control plane and worker node communication.*

---

## Part 11: Monitoring and Alerting (Extra Credit)

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

## Technical Challenges and Solutions

### Challenge 1: Flask and Werkzeug Version Compatibility

**Problem:** Initial deployment failed with `ImportError: cannot import name 'url_quote' from 'werkzeug.urls'`

**Root Cause:** Flask 2.1.3 incompatible with Werkzeug 3.x due to deprecated imports

**Solution:** Pinned Werkzeug to version 2.3.7 in requirements.txt
```
Flask==2.1.3
Werkzeug==2.3.7
pymongo==4.2.0
```

**Learning:** Importance of dependency version management and compatibility testing

---

### Challenge 2: Docker Image Architecture Mismatch

**Problem:** Pods in EKS failed with `exec /usr/local/bin/python: exec format error`

**Root Cause:** Docker image built on Apple Silicon (ARM64) incompatible with EKS nodes (AMD64)

**Solution:** Rebuilt image with explicit platform specification
```bash
docker buildx build --platform linux/amd64 \
  -t thetanishrana/todo-flask-app:2.0 --push .
```

**Learning:** Multi-architecture considerations critical for cloud deployments

---

### Challenge 3: EBS CSI Driver Not Pre-installed

**Problem:** MongoDB PVC stuck in Pending state with "no persistent volumes available"

**Root Cause:** AWS EKS does not include EBS CSI driver by default

**Solution:**
1. Installed EBS CSI driver as EKS addon
2. Created IAM policy with required EC2 permissions
3. Attached policy to node instance role
4. Restarted CSI controller pods

**IAM Policy Required:**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": [
      "ec2:CreateSnapshot",
      "ec2:AttachVolume",
      "ec2:DetachVolume",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInstances",
      "ec2:DescribeVolumes",
      "ec2:CreateVolume",
      "ec2:DeleteVolume"
    ],
    "Resource": "*"
  }]
}
```

**Learning:** AWS EKS requires explicit CSI driver installation for EBS volumes

---

### Challenge 4: Alertmanager Persistent Volume Configuration

**Problem:** Alertmanager StatefulSet stuck in Pending due to PVC without storage class

**Root Cause:** Helm chart volumeClaimTemplate not respecting storageClassName in values file

**Solution:**
1. Scaled StatefulSet to 0 replicas
2. Manually created PVC with correct storage class (gp2)
3. Scaled StatefulSet back to 1 replica
4. StatefulSet consumed pre-existing PVC

**Manual PVC Creation:**
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: storage-prometheus-alertmanager-0
  namespace: monitoring
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: gp2
  resources:
    requests:
      storage: 2Gi
```

**Learning:** StatefulSet volumeClaimTemplates are immutable; workarounds may be necessary

---

### Challenge 5: Prometheus Alert Rules Not Loading

**Problem:** Alert rules defined in values.yaml but not appearing in Prometheus configuration

**Root Cause:** Duplicate `server:` sections in prometheus-values.yaml causing the second section to override alert rules

**Solution:** Merged duplicate sections into single server configuration block

**Learning:** YAML structure validation critical for Helm chart deployments

---

## Key Learning Outcomes

### Technical Skills Acquired

1. **Container Orchestration**
   - Kubernetes architecture and resource management
   - Pod lifecycle management and scheduling
   - Service networking and load balancing
   - ConfigMaps and Secrets management

2. **Cloud Infrastructure**
   - AWS EKS cluster provisioning and management
   - VPC networking and security group configuration
   - IAM roles and policies for service permissions
   - EBS volume management and CSI drivers

3. **High Availability Patterns**
   - ReplicaSet self-healing mechanisms
   - Rolling update strategies for zero-downtime deployments
   - Health probes and readiness checks
   - Multi-zone pod distribution

4. **Observability and Monitoring**
   - Prometheus metrics collection and storage
   - PromQL query language for metric analysis
   - Alertmanager routing and notification
   - Webhook integration for external systems

5. **DevOps Practices**
   - Infrastructure as Code with YAML manifests
   - Helm package management
   - Version control for container images
   - Documentation and knowledge transfer

### Conceptual Understanding

1. **Declarative vs Imperative Management**
   - Kubernetes declarative API benefits
   - Desired state reconciliation loops
   - GitOps principles for configuration management

2. **Cloud-Native Architecture Principles**
   - Stateless application design
   - Persistent storage decoupling
   - Service discovery and DNS
   - Horizontal scaling capabilities

3. **Production Readiness Considerations**
   - Resource requests and limits
   - Quality of Service (QoS) classes
   - Liveness vs readiness probes
   - Graceful shutdown handling

---

## Cost Analysis

### AWS EKS Cost Breakdown

**Hourly Costs:**
- EKS Control Plane: $0.10/hour (flat rate)
- 2x t3.medium EC2 instances: $0.0416 each = $0.0832/hour
- 3x EBS gp2 volumes (11Gi total): ~$0.0012/hour
- Classic Load Balancer: $0.025/hour
- Data transfer (minimal): ~$0.001/hour
- **Total: ~$0.22/hour**

**Daily Cost (if left running):**
- $0.22/hour × 24 hours = **$5.28/day**

**Monthly Projection:**
- $5.28/day × 30 days = **$158.40/month**

**Actual Session Cost:**
- Cluster running time: ~11 hours
- Total cost incurred: ~$2.42

### Cost Optimization Strategies

1. **Cluster Shutdown:** Delete cluster when not in use
2. **Instance Type:** t3.medium provides good balance for testing
3. **Spot Instances:** Could reduce EC2 costs by 70% for non-critical workloads
4. **Storage Optimization:** Use gp3 instead of gp2 for better price/performance
5. **Reserved Instances:** Commit to 1-year term for 40% savings in production

### Cost Cleanup Procedure

```bash
# Delete application resources
kubectl delete -f k8s-eks/

# Delete monitoring stack
helm uninstall prometheus -n monitoring
kubectl delete namespace monitoring

# Verify PVCs deleted
kubectl get pvc --all-namespaces

# Delete EKS cluster (removes all AWS resources)
eksctl delete cluster --name todo-app-cluster --region us-east-1
```

**Note:** Cluster deletion takes approximately 10 minutes and removes all associated AWS resources including VPC, security groups, load balancers, and EBS volumes.

---

## Conclusion

This project successfully demonstrates comprehensive proficiency in modern cloud-native application deployment and management. All core assignment objectives and extra credit requirements were completed, encompassing:

1. **Application Development:** Created production-ready Flask application with health monitoring endpoints
2. **Containerization:** Built and published multi-architecture Docker images to public registry
3. **Local Orchestration:** Deployed and validated on Minikube Kubernetes cluster
4. **Self-Healing:** Demonstrated automatic pod recovery and service continuity
5. **Rolling Updates:** Implemented zero-downtime deployment strategy
6. **Cloud Deployment:** Provisioned production-grade AWS EKS infrastructure
7. **Monitoring:** Integrated complete Prometheus observability stack with Slack alerting

The implementation showcases industry best practices including:
- Infrastructure as Code for reproducibility
- Declarative configuration management
- Health probes for automatic failure detection
- Persistent storage for stateful applications
- Load balancing for high availability
- Comprehensive monitoring and alerting
- Detailed documentation for knowledge transfer

Total implementation time was approximately 11 hours with AWS costs maintained at $2.42 through efficient resource management.

This assignment provided valuable hands-on experience with technologies and practices essential for modern DevOps and Site Reliability Engineering roles.

---

## References

### Documentation
- Kubernetes Official Documentation: https://kubernetes.io/docs/
- Docker Documentation: https://docs.docker.com/
- AWS EKS User Guide: https://docs.aws.amazon.com/eks/
- Prometheus Documentation: https://prometheus.io/docs/
- Helm Documentation: https://helm.sh/docs/

### Tools and Services
- Docker Hub: https://hub.docker.com/r/thetanishrana/todo-flask-app
- eksctl: https://eksctl.io/
- Prometheus Helm Chart: https://github.com/prometheus-community/helm-charts

### Project Repository Structure
```
CBD_Assignment_2/
├── README.md                           # Main documentation (comprehensive academic presentation)
├── documentation/                      # Supporting documentation
│   ├── ASSIGNMENT_DOCUMENTATION.md     # Detailed technical documentation
│   ├── EKS_DEPLOYMENT_GUIDE.md        # AWS EKS deployment procedures
│   ├── ASSIGNMENT_COMPLETION_SUMMARY.md # Project completion checklist
│   ├── VERIFICATION_COMMANDS.md        # Quick reference commands
│   └── SLACK_SETUP.md                 # Slack webhook configuration guide
├── app.py                             # Flask application source code
├── requirements.txt                    # Python dependencies
├── Dockerfile                         # Container image definition
├── docker-compose.yml                 # Local development environment
├── ebs-csi-policy.json               # AWS IAM policy for EBS CSI driver
├── k8s/                               # Minikube Kubernetes manifests
│   ├── mongodb-pvc.yaml
│   ├── mongodb-deployment.yaml
│   ├── mongodb-service.yaml
│   ├── flask-deployment.yaml
│   └── flask-service.yaml
├── k8s-eks/                           # AWS EKS Kubernetes manifests
│   ├── mongodb-pvc.yaml
│   ├── mongodb-deployment.yaml
│   ├── mongodb-service.yaml
│   ├── flask-deployment.yaml
│   └── flask-service.yaml
├── prometheus-config/                 # Prometheus Helm values
│   ├── prometheus-values.yaml
│   └── alertmanager-pvc.yaml
├── screenshots/                       # Visual documentation (23 images)
├── static/                            # CSS and static assets
└── templates/                         # Flask HTML templates
```

---

**End of Documentation**

*This README serves as the primary technical submission document for Cloud and Big Data Assignment 2. All claims are supported by screenshots in the screenshots/ directory and detailed procedures in accompanying documentation files.*
