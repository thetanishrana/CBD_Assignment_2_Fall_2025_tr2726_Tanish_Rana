# AWS EKS Deployment Guide

Complete guide for deploying the Flask + MongoDB application to Amazon EKS.

## Overview

This guide covers:
- EKS cluster creation using eksctl
- Application deployment to EKS
- LoadBalancer service configuration
- Prometheus monitoring with Slack alerts
- Cost management and cleanup

## Prerequisites

- AWS CLI configured with credentials
- eksctl installed
- kubectl installed
- Helm installed
- Docker images pushed to Docker Hub (thetanishrana/todo-flask-app:1.0, 2.0)

## Part 1: EKS Cluster Creation

### 1.1 Create EKS Cluster

```bash
# Create cluster with 2 t3.medium nodes
eksctl create cluster \
  --name todo-app-cluster \
  --region us-east-1 \
  --nodegroup-name standard-workers \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 2 \
  --nodes-max 3 \
  --managed
```

**Time**: ~15-20 minutes

**What happens**:
- Creates VPC with public/private subnets across 2 AZs
- Deploys EKS control plane (Kubernetes master)
- Creates managed node group with 2 worker nodes
- Installs default addons: vpc-cni, kube-proxy, coredns, metrics-server
- Updates kubeconfig automatically

### 1.2 Verify Cluster

```bash
# Check cluster status
eksctl get cluster --region us-east-1

# Verify kubectl context
kubectl config current-context

# Check nodes
kubectl get nodes

# Expected output:
# NAME                         STATUS   ROLES    AGE   VERSION
# ip-192-168-x-x.ec2.internal  Ready    <none>   5m    v1.32.x
# ip-192-168-x-x.ec2.internal  Ready    <none>   5m    v1.32.x
```

## Part 2: Deploy Application to EKS

### 2.1 Review EKS-Specific Manifests

The `k8s-eks/` directory contains modified manifests:

**flask-service.yaml** (Changed):
- Type: `LoadBalancer` (was NodePort)
- Port: `80` (public HTTP port)
- TargetPort: `5000` (Flask app port)

**mongodb-pvc.yaml** (Changed):
- StorageClass: `gp2` (AWS EBS volume, was "standard")

### 2.2 Deploy Application

```bash
# Deploy all resources
kubectl apply -f k8s-eks/

# Watch deployment progress
kubectl get pods -w

# Expected output (after ~2 minutes):
# NAME                         READY   STATUS    RESTARTS   AGE
# flask-app-xxxxxxxxxx-xxxxx   1/1     Running   0          90s
# flask-app-xxxxxxxxxx-xxxxx   1/1     Running   0          90s
# flask-app-xxxxxxxxxx-xxxxx   1/1     Running   0          90s
# mongodb-xxxxxxxxxx-xxxxx     1/1     Running   0          2m
```

### 2.3 Verify Deployment

```bash
# Check deployments
kubectl get deployments

# Check services
kubectl get svc

# Check PVC
kubectl get pvc
# Should show: mongodb-pvc   Bound    pvc-xxx   1Gi        RWO            gp2
```

### 2.4 Get LoadBalancer URL

```bash
# Get external URL (wait for EXTERNAL-IP to populate)
kubectl get svc flask-app

# This may take 2-3 minutes. Output:
# NAME        TYPE           CLUSTER-IP      EXTERNAL-IP                       PORT(S)
# flask-app   LoadBalancer   10.100.x.x      xxx.us-east-1.elb.amazonaws.com   80:xxxxx/TCP

# Once EXTERNAL-IP shows, access the application:
curl http://xxx.us-east-1.elb.amazonaws.com
```

**Behind the scenes**: AWS creates an ELB (Elastic Load Balancer) that distributes traffic to the 3 Flask pods across worker nodes.

## Part 3: Prometheus Monitoring Setup

### 3.1 Create Slack Webhook

Follow the guide in `prometheus-config/SLACK_SETUP.md`:

1. Create Slack workspace or use existing
2. Create new app: "Prometheus Alerts"
3. Enable Incoming Webhooks
4. Add webhook to channel (e.g., #alerts)
5. Copy webhook URL

### 3.2 Configure Prometheus Values

Edit `prometheus-config/prometheus-values.yaml`:

```yaml
alertmanager:
  config:
    global:
      slack_api_url: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'
```

Replace `YOUR_SLACK_WEBHOOK_URL_HERE` with your actual webhook URL.

### 3.3 Install Prometheus with Helm

```bash
# Add Prometheus Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus with custom values
helm install prometheus prometheus-community/prometheus \
  -f prometheus-config/prometheus-values.yaml \
  --namespace monitoring \
  --create-namespace

# Wait for pods to be ready
kubectl get pods -n monitoring -w
```

### 3.4 Access Prometheus UI

```bash
# Port forward Prometheus server
kubectl port-forward -n monitoring svc/prometheus-server 9090:80

# Access at: http://localhost:9090
```

### 3.5 Access Alertmanager UI

```bash
# Port forward Alertmanager
kubectl port-forward -n monitoring svc/prometheus-alertmanager 9093:80

# Access at: http://localhost:9093
```

## Part 4: Test Monitoring and Alerting

### 4.1 Verify Prometheus Targets

1. Open http://localhost:9090
2. Go to **Status > Targets**
3. Verify all targets are "UP"

### 4.2 Test Alert by Deleting a Pod

```bash
# Get pod names
kubectl get pods -l app=flask-app

# Delete one pod
POD_NAME=$(kubectl get pods -l app=flask-app -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod $POD_NAME

# Watch for alert in Slack (within ~1-2 minutes)
# The alert should appear in your configured Slack channel

# Verify self-healing (new pod created automatically)
kubectl get pods -l app=flask-app
# Should still show 3 pods total
```

### 4.3 Test High Memory/CPU Alerts

You can stress test the application to trigger resource alerts:

```bash
# Install stress tool in a pod
kubectl run stress-test --image=polinux/stress --rm -it -- stress --cpu 2 --timeout 60s

# Monitor alerts in Prometheus and Slack
```

### 4.4 Verify Alert Resolution

Once the pod is back up or stress test ends:
- Prometheus should send a "resolved" notification to Slack
- Check Alertmanager UI to confirm alert is no longer firing

## Part 5: Screenshots for Documentation

Capture the following screenshots:

### EKS Cluster
1. AWS Console > EKS > Clusters > todo-app-cluster
2. Node group details
3. `kubectl get all` output
4. `kubectl get nodes` output

### Application Deployment
5. LoadBalancer URL in browser (showing To-Do app)
6. `kubectl get svc` showing LoadBalancer EXTERNAL-IP
7. `kubectl get pods -o wide` showing pods across nodes
8. `kubectl describe deployment flask-app`

### Prometheus Monitoring
9. Prometheus UI > Status > Targets
10. Prometheus UI > Alerts page
11. Alertmanager UI showing alert configuration
12. Slack channel showing alert notification

### Self-Healing Demo
13. Before deleting pod: `kubectl get pods`
14. Alert in Slack: "Pod flask-app-xxx is down"
15. After self-healing: `kubectl get pods` showing 3 pods again
16. Resolved alert in Slack

## Part 6: Cost Management

### 6.1 Estimated Costs

**EKS Control Plane**:
- $0.10/hour = $2.40/day
- Fixed cost regardless of workload

**EC2 Worker Nodes (2x t3.medium)**:
- $0.0416/hour per node
- 2 nodes = $0.0832/hour = $2.00/day

**EBS Volumes**:
- gp2: $0.10/GB-month
- 1 GB for MongoDB = $0.003/day
- Node volumes: ~$0.30/day

**Elastic Load Balancer**:
- $0.025/hour = $0.60/day
- Data processing: $0.008/GB (minimal for testing)

**Total Daily Cost**: ~$5.30/day ($159/month if left running)

### 6.2 Cost Optimization Tips

1. **Use for Assignment Only**: Delete cluster immediately after completion
2. **Smaller Nodes**: t3.small could work but t3.medium is safer for stability
3. **Single Node**: For testing only (loses high availability)
4. **Spot Instances**: 70% cheaper but can be terminated

### 6.3 AWS Free Tier

- EKS: Not included in free tier ($0.10/hour regardless)
- EC2 t3.medium: Not covered by free tier (t2.micro is, but too small)
- 750 hours/month of t2.micro is free for first 12 months

### 6.4 Monitor Costs

```bash
# Check AWS Cost Explorer in console
# Or use AWS CLI:
aws ce get-cost-and-usage \
  --time-period Start=2025-10-01,End=2025-10-30 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=SERVICE
```

## Part 7: Cleanup

**IMPORTANT**: Delete all resources to stop incurring charges!

### 7.1 Delete Application Resources

```bash
# Delete application
kubectl delete -f k8s-eks/

# Delete Prometheus
helm uninstall prometheus -n monitoring
kubectl delete namespace monitoring

# Verify PVC deleted (important - EBS volumes cost money!)
kubectl get pvc
```

### 7.2 Delete EKS Cluster

```bash
# Delete entire cluster and all AWS resources
eksctl delete cluster --name todo-app-cluster --region us-east-1

# This takes ~10 minutes and deletes:
# - Worker nodes
# - Node group
# - Control plane
# - VPC and networking
# - Security groups
# - Load balancers
```

### 7.3 Verify Cleanup

```bash
# Check EKS
eksctl get cluster --region us-east-1
# Should show: No clusters found

# Check EC2 instances (should be terminated)
aws ec2 describe-instances --region us-east-1 \
  --filters "Name=tag:alpha.eksctl.io/cluster-name,Values=todo-app-cluster" \
  --query "Reservations[].Instances[].State.Name"

# Check EBS volumes (should be deleted)
aws ec2 describe-volumes --region us-east-1 \
  --filters "Name=tag:kubernetes.io/cluster/todo-app-cluster,Values=owned"

# Check Load Balancers (should be deleted)
aws elbv2 describe-load-balancers --region us-east-1
```

## Part 8: Key Learnings

### EKS vs Minikube

| Aspect | Minikube | EKS |
|--------|----------|-----|
| **Environment** | Local laptop | AWS Cloud |
| **Nodes** | Single node | Multiple EC2 nodes |
| **High Availability** | No (single point of failure) | Yes (multi-AZ) |
| **Services** | NodePort (minikube service) | LoadBalancer (AWS ELB) |
| **Storage** | hostPath | EBS volumes (gp2/gp3) |
| **Networking** | Local | AWS VPC |
| **Cost** | Free | ~$5/day |
| **Use Case** | Development & testing | Production |

### LoadBalancer Service

**In Minikube**:
- LoadBalancer type not natively supported
- Falls back to NodePort
- Use `minikube service` to access

**In EKS**:
- LoadBalancer automatically creates AWS ELB
- Distributes traffic across nodes
- Provides public DNS name
- Handles SSL termination (with annotations)

### Persistent Storage

**In Minikube**:
- Uses `standard` storage class
- Maps to hostPath on Minikube node
- Data lost if cluster deleted

**In EKS**:
- Uses `gp2` or `gp3` storage class (AWS EBS)
- EBS volumes persist independently
- Must manually delete PVCs to delete volumes

### Prometheus in Production

Key considerations:
- **Resource Requirements**: Prometheus needs significant memory for large clusters
- **Retention**: Configure data retention period (default 15 days)
- **HA Setup**: Use multiple Prometheus replicas for production
- **Alert Fatigue**: Tune alert thresholds to avoid noise
- **Slack Rate Limits**: Group alerts to avoid hitting limits

## Troubleshooting

### EKS Cluster Creation Fails

```bash
# Check CloudFormation stacks
aws cloudformation describe-stacks --region us-east-1

# Delete stuck resources
eksctl delete cluster --name todo-app-cluster --region us-east-1 --wait
```

### Pods Not Starting

```bash
# Check pod events
kubectl describe pod <pod-name>

# Common issues:
# - ImagePullBackOff: Docker image not accessible
# - CrashLoopBackOff: App crashing, check logs
# - Pending: Insufficient resources or PVC issues
```

### LoadBalancer Stuck in Pending

```bash
# Check service events
kubectl describe svc flask-app

# Verify AWS Load Balancer Controller
kubectl get pods -n kube-system | grep aws-load-balancer

# Check AWS Console > EC2 > Load Balancers
```

### Prometheus Not Scraping Metrics

```bash
# Check Prometheus pod logs
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus

# Verify service discovery
# In Prometheus UI: Status > Service Discovery
```

### Alerts Not Sending to Slack

```bash
# Check Alertmanager logs
kubectl logs -n monitoring -l app.kubernetes.io/name=alertmanager

# Test webhook manually
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Test alert"}' \
  YOUR_WEBHOOK_URL

# Verify alertmanager config
kubectl get configmap -n monitoring prometheus-alertmanager -o yaml
```

## Conclusion

This deployment demonstrates:
- ✅ Production-grade Kubernetes on AWS EKS
- ✅ Multi-node cluster with high availability
- ✅ Cloud load balancer integration
- ✅ Persistent storage with EBS volumes
- ✅ Comprehensive monitoring with Prometheus
- ✅ Real-time alerting via Slack
- ✅ Self-healing and rolling updates
- ✅ Cost management and cleanup

**Total Estimated Time**: 45-60 minutes
**Estimated Cost**: $0.22 - $0.44 (for 1 hour of testing)
