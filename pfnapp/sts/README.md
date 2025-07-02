# STS Chart

A Helm chart for deploying **stateful applications** as Kubernetes StatefulSets.

## Overview

This chart is designed for stateful workloads that require persistent storage, stable network identities, and ordered deployment/scaling. Perfect for databases, message queues, distributed systems, and other applications that maintain state.

## Key Features

- **StatefulSet Workloads**: Optimized for stateful applications
- **Volume Claim Templates**: Per-pod persistent storage that scales with replicas
- **Stable Network Identity**: Predictable pod names and DNS entries
- **Ordered Operations**: Sequential pod deployment, scaling, and updates
- **Flexible Storage**: Standard volumes, simple mounts, and volume claim templates
- **Headless Service**: Built-in support for StatefulSet service discovery
- **Mixed Storage**: Combine per-pod storage with shared volumes

## Key Differences from Deploy Chart

| Feature | Deploy Chart | STS Chart |
|---------|--------------|-----------|
| **Workload Type** | Deployment | StatefulSet |
| **Storage** | Shared volumes | Per-pod + shared volumes |
| **Pod Identity** | Random names | Stable, ordered names |
| **Scaling** | Parallel | Sequential |
| **Auto-scaling** | ✅ HPA supported | ❌ Not recommended |
| **Rolling Updates** | Parallel | Sequential |

## Quick Start

### Basic Database Cluster

```yaml
# values.yaml
app:
  name: "postgres-cluster"

image:
  repository: "postgres"
  tag: "14"

replicaCount: 3

service:
  port: 5432
  targetPort: 5432

# Per-pod persistent storage
statefulset:
  volumeClaimTemplates:
    - metadata:
        name: postgres-data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: "fast-ssd"
        resources:
          requests:
            storage: 100Gi

volumeMounts:
  - name: postgres-data
    mountPath: /var/lib/postgresql/data

env:
  - name: POSTGRES_DB
    value: "myapp"
  - name: POSTGRES_USER
    value: "postgres"
  - name: POSTGRES_PASSWORD
    valueFrom:
      secretKeyRef:
        name: postgres-secret
        key: password
```

### Install

```bash
helm install postgres pfnapp/sts -f values.yaml
```

## Configuration

All configuration is done through the `values.yaml` file. The STS chart shares most configuration options with the Deploy chart, with key differences in storage and StatefulSet-specific settings.

### Application Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `app.name` | Application name | `"myapp"` |
| `app.version` | Application version | `"latest"` |
| `replicaCount` | Number of pod replicas | `1` |

### Image Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Container image repository | `"nginx"` |
| `image.tag` | Image tag | `"latest"` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `image.command` | Container command override (array) | `[]` |
| `image.args` | Container arguments override (array) | `[]` |
| `imagePullSecrets` | Image pull secrets | `[]` |

### StatefulSet Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `statefulset.serviceName` | Headless service name | Auto-generated |
| `statefulset.volumeClaimTemplates` | Volume claim templates for per-pod storage | `[]` |

#### Volume Claim Templates

```yaml
statefulset:
  volumeClaimTemplates:
    - metadata:
        name: data-storage
        annotations:
          volume.beta.kubernetes.io/storage-class: "fast-ssd"
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: "fast-ssd"
        resources:
          requests:
            storage: 50Gi
    
    - metadata:
        name: logs-storage
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: "standard"
        resources:
          requests:
            storage: 10Gi
```

### Service Configuration

StatefulSets typically use **headless services** for stable network identity:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.enabled` | Enable service creation | `true` |
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `service.targetPort` | Target port on pods | `80` |
| `service.clusterIP` | Set to "None" for headless service | `None` (recommended) |
| `service.annotations` | Service annotations | `{}` |

### Storage & Volumes

StatefulSets support **three storage patterns**:

#### 1. Volume Claim Templates (Per-Pod Storage)

```yaml
statefulset:
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: "fast-ssd"
        resources:
          requests:
            storage: 100Gi

volumeMounts:
  - name: data
    mountPath: /var/lib/app/data
```

#### 2. Shared Storage via Simple Volumes

```yaml
# Shared across all pods
simpleVolumes:
  - mountPath: "/shared/config"
    size: "1Gi"
    storageClass: "standard"
    accessModes: ["ReadWriteMany"]
    name: "shared-config"
```

#### 3. Mixed Storage Strategy

```yaml
# Per-pod data storage
statefulset:
  volumeClaimTemplates:
    - metadata:
        name: database-data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: "fast-ssd"
        resources:
          requests:
            storage: 200Gi

volumeMounts:
  - name: database-data
    mountPath: /var/lib/database

# Shared configuration
simpleMounts:
  - mountPath: "/etc/app-config"
    configMap: "database-config"

# Shared certificates
simpleVolumes:
  - mountPath: "/etc/ssl/certs"
    size: "1Gi"
    storageClass: "standard"
    accessModes: ["ReadWriteMany"]
```

### Environment Variables

Environment variables work identically to the Deploy chart:

#### Helm-Managed ConfigMap & Secret

```yaml
configMap:
  enabled: true
  data:
    CLUSTER_NAME: "postgres-cluster"
    REPLICATION_MODE: "master-slave"

secret:
  enabled: true
  data:
    DB_PASSWORD: "c2VjcmV0cGFzcw=="
    REPLICATION_PASSWORD: "cmVwbGljYXRpb25zZWNyZXQ="
```

#### External References

```yaml
env:
  - name: POD_NAME
    valueFrom:
      fieldRef:
        fieldPath: metadata.name
  
  - name: POD_NAMESPACE
    valueFrom:
      fieldRef:
        fieldPath: metadata.namespace
  
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:
        name: database-secret
        key: connection-string

envFrom:
  - configMapRef:
      name: database-config
  - secretRef:
      name: database-secrets
```

### Health Checks

Health checks are especially important for StatefulSets due to ordered operations:

#### Simplified Probes (Recommended)

```yaml
simpleLivenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 60  # Longer for databases
  periodSeconds: 30
  timeoutSeconds: 10
  failureThreshold: 3

simpleReadinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3

simpleStartupProbe:
  httpGet:
    path: /startup
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
  failureThreshold: 60  # Allow longer startup time
```

#### TCP/Exec Probes for Databases

```yaml
livenessProbe:
  tcpSocket:
    port: 5432
  initialDelaySeconds: 60
  periodSeconds: 30

readinessProbe:
  exec:
    command:
      - /bin/sh
      - -c
      - pg_isready -U postgres
  initialDelaySeconds: 30
  periodSeconds: 10
```

### Resource Management

StatefulSets often require more resources and consistent allocation:

```yaml
resources:
  limits:
    cpu: "2000m"
    memory: "4Gi"
  requests:
    cpu: "1000m"    # More consistent for databases
    memory: "2Gi"
```

### Security Settings

Same as Deploy chart, but often more restrictive for databases:

```yaml
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 999  # postgres user
  fsGroup: 999
  fsGroupChangePolicy: "OnRootMismatch"

securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: false  # Databases need write access
  runAsNonRoot: true
  runAsUser: 999
  capabilities:
    drop:
      - ALL
```

### Networking

StatefulSets benefit from stable network configuration:

```yaml
service:
  type: ClusterIP
  clusterIP: "None"  # Headless service
  port: 5432
  targetPort: 5432

containerPorts:
  - containerPort: 5432
    name: postgres
```

### Scheduling & Placement

Anti-affinity is crucial for StatefulSet availability:

```yaml
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
            - key: app.kubernetes.io/name
              operator: In
              values:
                - postgres-cluster
        topologyKey: kubernetes.io/hostname

nodeSelector:
  node-type: "database"

tolerations:
  - key: "database-node"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"
```

## Examples

### PostgreSQL Cluster

```yaml
app:
  name: "postgres-cluster"

image:
  repository: "postgres"
  tag: "14-alpine"

replicaCount: 3

service:
  type: ClusterIP
  clusterIP: "None"  # Headless service
  port: 5432
  targetPort: 5432

containerPorts:
  - containerPort: 5432
    name: postgres

statefulset:
  volumeClaimTemplates:
    - metadata:
        name: postgres-data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: "fast-ssd"
        resources:
          requests:
            storage: 100Gi

volumeMounts:
  - name: postgres-data
    mountPath: /var/lib/postgresql/data

configMap:
  enabled: true
  data:
    POSTGRES_DB: "myapp"
    POSTGRES_USER: "postgres"

secret:
  enabled: true
  data:
    POSTGRES_PASSWORD: "c2VjcmV0cGFzcw=="

resources:
  requests:
    memory: "2Gi"
    cpu: "1000m"
  limits:
    memory: "4Gi"
    cpu: "2000m"

livenessProbe:
  tcpSocket:
    port: 5432
  initialDelaySeconds: 60
  periodSeconds: 30

readinessProbe:
  exec:
    command:
      - /bin/sh
      - -c
      - pg_isready -U postgres
  initialDelaySeconds: 30
  periodSeconds: 10

affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
            - key: app.kubernetes.io/name
              operator: In
              values:
                - postgres-cluster
        topologyKey: kubernetes.io/hostname
```

### Elasticsearch Cluster

```yaml
app:
  name: "elasticsearch"

image:
  repository: "elasticsearch"
  tag: "8.8.0"

replicaCount: 3

service:
  clusterIP: "None"
  ports:
    - name: http
      port: 9200
      targetPort: 9200
    - name: transport
      port: 9300
      targetPort: 9300

containerPorts:
  - containerPort: 9200
    name: http
  - containerPort: 9300
    name: transport

statefulset:
  volumeClaimTemplates:
    - metadata:
        name: elasticsearch-data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: "fast-ssd"
        resources:
          requests:
            storage: 200Gi

volumeMounts:
  - name: elasticsearch-data
    mountPath: /usr/share/elasticsearch/data

env:
  - name: cluster.name
    value: "elasticsearch-cluster"
  - name: node.name
    valueFrom:
      fieldRef:
        fieldPath: metadata.name
  - name: discovery.seed_hosts
    value: "elasticsearch-0.elasticsearch,elasticsearch-1.elasticsearch,elasticsearch-2.elasticsearch"
  - name: cluster.initial_master_nodes
    value: "elasticsearch-0,elasticsearch-1,elasticsearch-2"

resources:
  requests:
    memory: "4Gi"
    cpu: "1000m"
  limits:
    memory: "8Gi"
    cpu: "2000m"

simpleLivenessProbe:
  httpGet:
    path: /_cluster/health
    port: 9200
  initialDelaySeconds: 90
  periodSeconds: 30

simpleReadinessProbe:
  httpGet:
    path: /_cluster/health?local=true
    port: 9200
  initialDelaySeconds: 30
  periodSeconds: 10
```

## Important Notes

### ⚠️ Auto-scaling Not Supported

StatefulSets do **not** support Horizontal Pod Autoscaling (HPA) due to their ordered nature and persistent storage requirements. Scale manually:

```bash
kubectl scale statefulset my-statefulset --replicas=5
```

### 🔄 Rolling Updates

StatefulSets perform rolling updates **sequentially** (one pod at a time) to maintain consistency:

```yaml
# In the StatefulSet spec (automatically handled)
updateStrategy:
  type: RollingUpdate
  rollingUpdate:
    partition: 0  # Update all pods
```

### 💾 Storage Considerations

- **Volume Claim Templates** create persistent storage that **persists after pod deletion**
- **Storage is not automatically deleted** when the StatefulSet is deleted
- **Scaling down does not delete PVCs** - manual cleanup required
- **Choose storage classes carefully** - some don't support volume expansion

### 🔗 Network Identity

StatefulSet pods have predictable names and DNS entries:

```
# Pod names
myapp-0, myapp-1, myapp-2, ...

# DNS entries (with headless service)
myapp-0.myapp.namespace.svc.cluster.local
myapp-1.myapp.namespace.svc.cluster.local
```

## Migration from Combined Chart

If migrating from the previous combined chart:

1. Remove `deploymentType: "statefulset"` from your values
2. Use `pfnapp/sts` instead of `pfnapp/deploy-old`
3. Follow the [Migration Guide](../../MIGRATION.md)

## Dependencies

- [Common Chart](../common/) v1.0.0 - Shared templates and helpers

## Chart Information

- **Type**: Application
- **Version**: 2.0.0
- **App Version**: latest
- **Maintainer**: pfnapp-team
- **Home**: https://pfnapp.github.io/charts

## Related Documentation

- [Deploy Chart](../deploy/) - For Deployment workloads
- [Volume Examples](../../VOLUMES.md) - Storage configuration examples
- [Migration Guide](../../MIGRATION.md) - Upgrade from combined chart