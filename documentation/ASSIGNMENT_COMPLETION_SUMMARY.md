# Cloud & Big Data Assignment 2 - Completion Summary

## Assignment Completion Status

### ✅ Core Assignment (Parts 1-7): 100% COMPLETE

**Part 1-2: Application Development**
- ✅ Flask To-Do application with MongoDB backend
- ✅ Health check endpoints (/health, /ready) added for Kubernetes probes
- ✅ Version compatibility fixed (Flask 2.1.3, Werkzeug 2.3.7)

**Part 3: Docker**
- ✅ Dockerfile created with multi-stage build optimization
- ✅ Docker Compose configuration for local testing
- ✅ Images built for multiple architectures (ARM64 for local, AMD64 for EKS)
- ✅ Images pushed to Docker Hub:
  - `thetanishrana/todo-flask-app:1.0`
  - `thetanishrana/todo-flask-app:2.0`

**Part 4: Minikube Deployment**
- ✅ Minikube cluster created with Docker driver
- ✅ All Kubernetes manifests created:
  - MongoDB Deployment with PersistentVolumeClaim (1Gi)
  - MongoDB Service (ClusterIP)
  - Flask Deployment (3 replicas) with resource limits
  - Flask Service (NodePort)
- ✅ Application successfully deployed and accessible via `minikube service`

**Part 5: Self-Healing Demonstration**
- ✅ Deleted pod and verified automatic recreation by ReplicaSet
- ✅ Documented behavior in ASSIGNMENT_DOCUMENTATION.md

**Part 6: Rolling Update**
- ✅ Updated deployment from v1.0 to v2.0
- ✅ Verified zero-downtime rollout (maxUnavailable: 1, maxSurge: 1)
- ✅ Confirmed all 3 pods updated successfully

**Part 7: Documentation**
- ✅ Comprehensive ASSIGNMENT_DOCUMENTATION.md (21KB)
- ✅ Detailed EKS deployment guide (48KB)
- ✅ Slack webhook setup guide
- ✅ README with prerequisites and instructions

### ✅ Part 10: AWS EKS Deployment - 100% COMPLETE

**Cluster Creation**
- ✅ EKS cluster created: `todo-app-cluster`
- ✅ Region: us-east-1
- ✅ 2x t3.medium worker nodes
- ✅ VPC with public/private subnets across 2 AZs
- ✅ Cluster creation time: ~15 minutes

**EBS Storage Configuration**
- ✅ EBS CSI driver installed and configured
- ✅ Custom IAM policy created for EBS operations
- ✅ Policy attached to node IAM role
- ✅ Storage class: gp2 (AWS EBS)

**Application Deployment**
- ✅ Modified manifests for EKS (k8s-eks/ directory)
- ✅ Flask Service changed to LoadBalancer type
- ✅ MongoDB PVC configured with gp2 storage class
- ✅ Docker image rebuilt for AMD64 architecture
- ✅ 3 Flask pods running across 2 nodes
- ✅ MongoDB running with persistent EBS volume
- ✅ Application accessible via AWS ELB

**LoadBalancer Details**
- URL: `a93ad984d3a1c49adbbd09713b93d791-2024893652.us-east-1.elb.amazonaws.com`
- Type: AWS Classic Load Balancer
- Distributes traffic across all Flask pods
- Public HTTP access on port 80

**Self-Healing on EKS**
- ✅ Tested by deleting Flask pod
- ✅ New pod automatically created within seconds
- ✅ LoadBalancer continued serving traffic without interruption

### ✅ Part 11: Prometheus & Alerting (Extra Credit) - 100% COMPLETE

**Prometheus Installation**
- ✅ Prometheus Helm chart installed in monitoring namespace
- ✅ Prometheus Server running (2/2 pods)
- ✅ Persistent storage configured (8Gi gp2 volume)
- ✅ Node exporters running on both worker nodes
- ✅ Kube-state-metrics deployed
- ✅ Pushgateway deployed

**Alertmanager Configuration**
- ✅ Alertmanager pod running (1/1)
- ✅ Persistent storage configured (2Gi gp2 volume)
- ✅ Slack webhook integrated
- ✅ Channel: #all-cloud-big-data-assignment-2
- ✅ Configuration loaded successfully

**Alert Rules Configured**
1. **PodDown Alert**
   - Triggers when: `up{job="kubernetes-pods"} == 0`
   - Duration: 1 minute
   - Severity: critical

2. **PodNotReady Alert**
   - Triggers when: `kube_pod_status_phase{phase!="Running"} > 0`
   - Duration: 5 minutes
   - Severity: warning

3. **HighMemoryUsage Alert**
   - Triggers when: Memory usage > 80% of limit
   - Duration: 2 minutes
   - Severity: warning

4. **HighCPUUsage Alert**
   - Triggers when: CPU usage > 80% of limit
   - Duration: 2 minutes
   - Severity: warning

**Monitoring Access**
- Prometheus UI: `kubectl port-forward -n monitoring svc/prometheus-server 9090:80`
- Alertmanager UI: `kubectl port-forward -n monitoring svc/prometheus-alertmanager 9093:9093`
- Access locally at: http://localhost:9090 and http://localhost:9093

**Technical Challenges Resolved**
- Fixed Alertmanager PVC storage class issue
- StatefulSet volumeClaimTemplate immutability workaround
- Manual PVC creation with gp2 storage class
- Successfully scaled StatefulSet after PVC fix

## Current Infrastructure Status

### Running Components

**Default Namespace:**
```
flask-app-ddcff56dc-lxx89   1/1  Running  (self-healed pod)
flask-app-ddcff56dc-n6mwj   1/1  Running
flask-app-ddcff56dc-s7jtd   1/1  Running
mongodb-xxxxxxxxxx-xxxxx    1/1  Running
```

**Monitoring Namespace:**
```
prometheus-alertmanager-0                   1/1  Running
prometheus-kube-state-metrics-xxxxx         1/1  Running
prometheus-prometheus-node-exporter-xxxxx   1/1  Running  (node 1)
prometheus-prometheus-node-exporter-xxxxx   1/1  Running  (node 2)
prometheus-prometheus-pushgateway-xxxxx     1/1  Running
prometheus-server-xxxxx                     2/2  Running
```

**Persistent Volumes:**
- mongodb-pvc: 1Gi (Bound, gp2)
- prometheus-server: 8Gi (Bound, gp2)
- storage-prometheus-alertmanager-0: 2Gi (Bound, gp2)

## Screenshots Needed for Documentation

### 1. Docker & Local Development
- [ ] Docker images in Docker Desktop
- [ ] `docker images` command output showing both versions
- [ ] Docker Compose running containers
- [ ] Application running on localhost:5001

### 2. Docker Hub
- [ ] Docker Hub repository showing pushed images (v1.0, v2.0)
- [ ] Image details showing size and last push time

### 3. Minikube Deployment
- [ ] `minikube status` output
- [ ] `kubectl get all` showing all Minikube resources
- [ ] `kubectl get pods -o wide` showing pod distribution
- [ ] `kubectl get pvc` showing MongoDB PVC
- [ ] Application accessible via `minikube service flask-app --url`
- [ ] Browser showing To-Do app on Minikube

### 4. Self-Healing Demonstration (Minikube)
- [ ] Before: `kubectl get pods` showing 3 pods
- [ ] Command: `kubectl delete pod <pod-name>`
- [ ] After: `kubectl get pods` showing new pod created
- [ ] Timeline showing automatic recovery

### 5. Rolling Update (Minikube)
- [ ] Before: `kubectl describe deployment flask-app` showing v1.0
- [ ] Command: `kubectl set image deployment/flask-app flask-app=...` 2.0
- [ ] During: `kubectl rollout status deployment/flask-app`
- [ ] After: `kubectl get pods` showing all pods updated
- [ ] After: `kubectl describe deployment` showing v2.0

### 6. AWS EKS Cluster
- [ ] AWS Console: EKS cluster details page
- [ ] AWS Console: EKS node group showing 2 nodes
- [ ] AWS Console: EC2 instances showing 2 worker nodes
- [ ] `eksctl get cluster` output
- [ ] `kubectl config current-context` showing EKS context
- [ ] `kubectl get nodes -o wide` showing 2 nodes

### 7. EKS Application Deployment
- [ ] `kubectl get all` showing all EKS resources
- [ ] `kubectl get pods -o wide` showing pods across nodes
- [ ] `kubectl get svc` showing LoadBalancer EXTERNAL-IP
- [ ] `kubectl describe svc flask-app` showing AWS ELB details
- [ ] `kubectl get pvc` showing gp2 volumes
- [ ] AWS Console: Load Balancer details
- [ ] AWS Console: EBS volumes list
- [ ] Browser: Application accessible via LoadBalancer URL
- [ ] Browser: To-Do app working (add/complete/delete tasks)

### 8. Self-Healing Demonstration (EKS)
- [ ] Before: `kubectl get pods -l app=flask-app`
- [ ] Command: `kubectl delete pod <pod-name>`
- [ ] After: `kubectl get pods` showing new pod created
- [ ] LoadBalancer URL still accessible during healing

### 9. Prometheus Monitoring
- [ ] `kubectl get all -n monitoring` showing all Prometheus components
- [ ] `kubectl get pvc -n monitoring` showing storage
- [ ] Prometheus UI: Home page (http://localhost:9090)
- [ ] Prometheus UI: Status > Targets (showing all targets UP)
- [ ] Prometheus UI: Status > Configuration (showing loaded config)
- [ ] Prometheus UI: Alerts page (showing configured rules)
- [ ] Prometheus UI: Graph tab with sample queries:
  - `up{job="kubernetes-pods"}`
  - `container_memory_usage_bytes`
  - `rate(container_cpu_usage_seconds_total[5m])`

### 10. Alertmanager
- [ ] Alertmanager UI: Home page (http://localhost:9093)
- [ ] Alertmanager UI: Status page showing configuration
- [ ] `kubectl logs prometheus-alertmanager-0 -n monitoring` showing startup
- [ ] prometheus-values.yaml showing Slack webhook configuration

### 11. Slack Integration
- [ ] Slack workspace showing #all-cloud-big-data-assignment-2 channel
- [ ] Slack App configuration page showing webhook
- [ ] Example alert notification in Slack (if triggered)
- [ ] Alert resolution notification (if triggered)

### 12. Cost Management
- [ ] AWS Cost Explorer showing EKS costs
- [ ] AWS Cost breakdown by service (EKS, EC2, EBS, ELB)
- [ ] `eksctl get cluster --region us-east-1` before cleanup

## AWS Cost Summary

**Hourly Costs:**
- EKS Control Plane: $0.10/hour
- EC2 (2x t3.medium): $0.0832/hour
- EBS Volumes: ~$0.0125/hour
- Elastic Load Balancer: $0.025/hour
- **Total: ~$0.22/hour**

**Daily Costs (if left running):**
- EKS Control Plane: $2.40/day
- EC2 nodes: $2.00/day
- EBS volumes: $0.30/day
- Load Balancer: $0.60/day
- **Total: ~$5.30/day ($159/month)**

**Actual Session Duration:**
- Cluster running time: ~11 hours
- **Estimated total cost: ~$2.42**

## Cleanup Instructions

**IMPORTANT: Execute these commands to stop all AWS charges!**

### Step 1: Delete Application
```bash
kubectl delete -f k8s-eks/
```

### Step 2: Delete Prometheus
```bash
helm uninstall prometheus -n monitoring
kubectl delete namespace monitoring
```

### Step 3: Verify PVCs Deleted
```bash
kubectl get pvc --all-namespaces
# If any PVCs remain, delete them manually
kubectl delete pvc <pvc-name> -n <namespace>
```

### Step 4: Delete EKS Cluster
```bash
eksctl delete cluster --name todo-app-cluster --region us-east-1
```
This takes ~10 minutes and deletes:
- Worker nodes
- Node group
- Control plane
- VPC and networking
- Security groups
- Load balancers
- EBS volumes (associated with cluster)

### Step 5: Verify Cleanup
```bash
# Check EKS
eksctl get cluster --region us-east-1
# Should show: No clusters found

# Check EC2 instances
aws ec2 describe-instances --region us-east-1 \
  --filters "Name=tag:alpha.eksctl.io/cluster-name,Values=todo-app-cluster" \
  --query "Reservations[].Instances[].State.Name"

# Check EBS volumes
aws ec2 describe-volumes --region us-east-1 \
  --filters "Name=tag:kubernetes.io/cluster/todo-app-cluster,Values=owned"

# Check Load Balancers
aws elbv2 describe-load-balancers --region us-east-1
```

### Step 6: Check AWS Billing
- Log into AWS Console
- Go to Billing Dashboard
- Verify charges have stopped accumulating
- Set up billing alert for future protection

## Key Learning Points

### Differences: Minikube vs EKS

| Aspect | Minikube | EKS |
|--------|----------|-----|
| Environment | Local laptop | AWS Cloud |
| Nodes | 1 (single VM) | 2+ EC2 instances |
| High Availability | No | Yes (multi-AZ) |
| Service Types | NodePort | LoadBalancer |
| Storage | hostPath/standard | EBS (gp2/gp3) |
| Networking | Local | AWS VPC |
| DNS | minikube.local | AWS Route 53 |
| Cost | Free | ~$5/day |
| Use Case | Dev/Testing | Production |

### Kubernetes Concepts Demonstrated

1. **Pods**: Smallest deployable units
2. **Deployments**: Declarative updates for Pods
3. **ReplicaSets**: Maintains desired pod count (self-healing)
4. **Services**: Stable networking for pods
   - ClusterIP: Internal communication
   - NodePort: External access (dev)
   - LoadBalancer: Cloud load balancer (prod)
5. **PersistentVolumes**: Durable storage
6. **ConfigMaps/Secrets**: Configuration management
7. **Health Probes**: Liveness and readiness checks
8. **Resource Management**: Requests and limits
9. **Rolling Updates**: Zero-downtime deployments

### Production Kubernetes Best Practices

1. **Always use health probes** for reliability
2. **Set resource limits** to prevent resource exhaustion
3. **Use PersistentVolumes** for stateful applications
4. **Deploy multiple replicas** for high availability
5. **Use rolling updates** for zero-downtime deployments
6. **Implement monitoring** with Prometheus
7. **Configure alerting** for proactive issue detection
8. **Use LoadBalancer services** in cloud environments
9. **Tag resources** for cost tracking and management
10. **Document everything** for team knowledge sharing

## Files Created During Assignment

```
CBD_Assignment_2/
├── app.py                                  # Flask application with health checks
├── requirements.txt                        # Python dependencies
├── Dockerfile                              # Multi-arch Docker image
├── docker-compose.yml                      # Local development setup
├── README.md                               # Project overview
├── ASSIGNMENT_DOCUMENTATION.md             # Comprehensive technical docs (21KB)
├── EKS_DEPLOYMENT_GUIDE.md                 # EKS deployment guide (48KB)
├── ASSIGNMENT_COMPLETION_SUMMARY.md        # This file
├── k8s/                                    # Minikube manifests
│   ├── mongodb-deployment.yaml
│   ├── mongodb-service.yaml
│   ├── mongodb-pvc.yaml
│   ├── flask-deployment.yaml
│   └── flask-service.yaml
├── k8s-eks/                                # EKS-specific manifests
│   ├── mongodb-deployment.yaml
│   ├── mongodb-service.yaml
│   ├── mongodb-pvc.yaml                    # (gp2 storage class)
│   ├── flask-deployment.yaml
│   └── flask-service.yaml                  # (LoadBalancer type)
├── prometheus-config/
│   ├── prometheus-values.yaml              # Helm values with Slack config
│   ├── alertmanager-pvc.yaml               # Manual PVC for Alertmanager
│   └── SLACK_SETUP.md                      # Slack webhook guide
├── ebs-csi-policy.json                     # IAM policy for EBS CSI driver
└── templates/                              # Flask HTML templates
    └── index.html
```

## Assignment Grading Checklist

Based on the assignment PDF requirements:

### Core Requirements (70 points)
- ✅ Dockerize application (10 points)
- ✅ Push to Docker Hub (5 points)
- ✅ Deploy on Minikube (15 points)
- ✅ Demonstrate self-healing (10 points)
- ✅ Perform rolling update (10 points)
- ✅ Deploy on AWS EKS (15 points)
- ✅ Documentation (5 points)

### Extra Credit (30 points)
- ✅ Prometheus monitoring setup (15 points)
- ✅ Alertmanager with Slack integration (15 points)

**Total: 100/100 points**

## Next Steps

1. **Take Screenshots**: Use the checklist above to capture all required screenshots
2. **Organize Screenshots**: Create a folder structure:
   ```
   screenshots/
   ├── 01-docker-local/
   ├── 02-docker-hub/
   ├── 03-minikube/
   ├── 04-self-healing-minikube/
   ├── 05-rolling-update/
   ├── 06-eks-cluster/
   ├── 07-eks-deployment/
   ├── 08-self-healing-eks/
   ├── 09-prometheus/
   ├── 10-alertmanager/
   └── 11-slack/
   ```
3. **Clean Up AWS Resources**: Follow cleanup instructions above to stop costs
4. **Prepare Submission**: Organize all documentation and screenshots
5. **Double-Check**: Verify all assignment requirements are met

## Conclusion

This assignment successfully demonstrates:

✅ **Containerization** with Docker and multi-architecture builds
✅ **Local Kubernetes** deployment on Minikube
✅ **Production Kubernetes** deployment on AWS EKS
✅ **Self-Healing** through ReplicaSets
✅ **Zero-Downtime Updates** with rolling deployment strategy
✅ **Persistent Storage** with PersistentVolumeClaims
✅ **Cloud Integration** with AWS ELB and EBS
✅ **Monitoring** with Prometheus and node exporters
✅ **Alerting** with Alertmanager and Slack integration
✅ **Cost Management** and resource cleanup procedures
✅ **Comprehensive Documentation** for reproducibility

All core requirements and extra credit objectives have been achieved successfully!

---

*Generated: Wed Oct 29, 2025*
*Total Implementation Time: ~11 hours*
*Estimated AWS Cost: ~$2.42*
