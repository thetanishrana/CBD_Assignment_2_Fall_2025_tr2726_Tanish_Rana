# Verification Commands - Assignment Validation

Use these commands to verify the assignment completion and demonstrate functionality.

## 1. Verify Docker Images

```bash
# Check local images
docker images | grep todo-flask-app

# Expected output:
# thetanishrana/todo-flask-app   2.0    ...   ... ago   ...MB
# thetanishrana/todo-flask-app   1.0    ...   ... ago   ...MB
# thetanishrana/todo-flask-app   latest ...   ... ago   ...MB
```

## 2. Verify Docker Compose Deployment

```bash
# Check running containers
docker compose ps

# Check container logs
docker logs todo-flask-app --tail=20
docker logs todo-mongodb --tail=20

# Test application
curl http://localhost:5001/health
curl http://localhost:5001/ready
curl -s http://localhost:5001/ | head -20
```

## 3. Verify Kubernetes Cluster

```bash
# Check Minikube status
minikube status

# Check nodes
kubectl get nodes

# Check all resources
kubectl get all

# Check persistent volume claim
kubectl get pvc
kubectl describe pvc mongodb-pvc
```

## 4. Verify Application Deployment

```bash
# Check deployments
kubectl get deployments
kubectl describe deployment flask-app
kubectl describe deployment mongodb

# Check pods
kubectl get pods -o wide
kubectl get pods -l app=flask-app
kubectl get pods -l app=mongodb

# Check services
kubectl get svc
kubectl describe svc flask-app
kubectl describe svc mongodb
```

## 5. Verify ReplicaSets

```bash
# List ReplicaSets
kubectl get rs

# Expected output shows both v1.0 (0 replicas) and v2.0 (3 replicas):
# flask-app-8d94cc4c8   3   3   3   (v2.0)
# flask-app-9488d77d5   0   0   0   (v1.0)

# Describe current ReplicaSet
kubectl describe rs flask-app-8d94cc4c8
```

## 6. Test Self-Healing

```bash
# Get current pods
kubectl get pods -l app=flask-app

# Delete one pod
POD_NAME=$(kubectl get pods -l app=flask-app -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod $POD_NAME

# Watch new pod being created (should see 3 pods total within seconds)
kubectl get pods -l app=flask-app -w
# Press Ctrl+C to exit watch mode

# Verify 3 replicas maintained
kubectl get pods -l app=flask-app
```

## 7. Verify Rolling Update

```bash
# Check rollout history
kubectl rollout history deployment/flask-app

# Expected output:
# REVISION  CHANGE-CAUSE
# 1         <none>        (v1.0)
# 2         <none>        (v2.0)

# Check current image version
kubectl get deployment flask-app -o jsonpath='{.spec.template.spec.containers[0].image}'
# Expected: thetanishrana/todo-flask-app:2.0
```

## 8. Verify Health Probes

```bash
# Check liveness probe configuration
kubectl get deployment flask-app -o jsonpath='{.spec.template.spec.containers[0].livenessProbe}' | jq

# Check readiness probe configuration
kubectl get deployment flask-app -o jsonpath='{.spec.template.spec.containers[0].readinessProbe}' | jq

# Test health endpoints from inside cluster
POD_NAME=$(kubectl get pods -l app=flask-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD_NAME -- curl -s http://localhost:5000/health
kubectl exec $POD_NAME -- curl -s http://localhost:5000/ready
```

## 9. Access Application

```bash
# Get Minikube service URL
minikube service flask-app --url

# Or use port forwarding
kubectl port-forward svc/flask-app 8080:5000 &
# Then access: http://localhost:8080

# Test the application
curl -s http://localhost:8080/
curl -s http://localhost:8080/health
curl -s http://localhost:8080/ready
```

## 10. View Logs and Events

```bash
# View pod logs
kubectl logs -l app=flask-app --tail=50
kubectl logs -l app=mongodb --tail=50

# View cluster events
kubectl get events --sort-by='.lastTimestamp' | tail -20

# View specific pod events
POD_NAME=$(kubectl get pods -l app=flask-app -o jsonpath='{.items[0].metadata.name}')
kubectl describe pod $POD_NAME | grep -A 20 "Events:"
```

## 11. Test Rollback (Optional)

```bash
# Rollback to previous version
kubectl rollout undo deployment/flask-app

# Watch rollback progress
kubectl rollout status deployment/flask-app

# Verify rolled back to v1.0
kubectl get deployment flask-app -o jsonpath='{.spec.template.spec.containers[0].image}'

# Roll forward to v2.0 again
kubectl rollout undo deployment/flask-app
```

## 12. Performance and Resource Verification

```bash
# Check resource usage
kubectl top nodes
kubectl top pods

# Check resource limits
kubectl describe deployment flask-app | grep -A 10 "Limits:"
kubectl describe deployment flask-app | grep -A 10 "Requests:"
```

## 13. Scale Application (Bonus)

```bash
# Scale to 5 replicas
kubectl scale deployment/flask-app --replicas=5

# Watch pods being created
kubectl get pods -l app=flask-app -w

# Scale back to 3
kubectl scale deployment/flask-app --replicas=3
```

## 14. Cleanup Commands

```bash
# Stop Docker Compose
docker compose down

# Delete Kubernetes resources
kubectl delete -f k8s/

# Stop Minikube
minikube stop

# Delete Minikube cluster
minikube delete
```

## Expected Results Summary

### Docker Compose
- ✅ 2 containers running (flask-app, mongodb)
- ✅ Named volume for MongoDB data
- ✅ Application accessible on port 5001
- ✅ Health endpoints returning 200 status

### Kubernetes
- ✅ 3 Flask pods in Running state (1/1 Ready)
- ✅ 1 MongoDB pod in Running state (1/1 Ready)
- ✅ PVC bound with 1Gi storage
- ✅ 2 ReplicaSets (v1.0 with 0 replicas, v2.0 with 3 replicas)
- ✅ 2 Services (flask-app NodePort, mongodb ClusterIP)
- ✅ Health probes configured and passing

### Self-Healing
- ✅ Deleted pod replaced within seconds
- ✅ 3 replicas maintained throughout
- ✅ No manual intervention required

### Rolling Update
- ✅ Smooth transition from v1.0 to v2.0
- ✅ Zero downtime during update
- ✅ All pods now running v2.0
- ✅ Rollout history shows 2 revisions

## Troubleshooting

### If pods are not ready:
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### If service not accessible:
```bash
kubectl get svc
minikube service list
```

### If PVC not bound:
```bash
kubectl describe pvc mongodb-pvc
kubectl get pv
```

### If health checks failing:
```bash
kubectl get events --field-selector involvedObject.name=<pod-name>
kubectl logs <pod-name>
```
