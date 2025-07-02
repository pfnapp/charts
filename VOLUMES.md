# Volume Handling Examples

This document provides examples of how to handle volumes in both `deploy` (Deployment) and `sts` (StatefulSet) charts.

## Key Differences

### Deploy Chart (Deployments)
- Uses **external PVCs** or **shared storage**
- Volumes are **shared across pod replicas**
- Good for **stateless apps** with temporary storage needs
- Uses `simpleVolumes` or standard `volumes`/`volumeMounts`

### STS Chart (StatefulSets)
- Uses **volumeClaimTemplates** for **per-pod storage**
- Each pod gets its **own persistent volume**
- Perfect for **stateful apps** like databases
- Uses `volumeClaimTemplates` + optional shared volumes

## Examples

### 1. Deploy Chart - Shared Persistent Storage

```yaml
# values-deploy-shared.yaml
app:
  name: "web-app"

replicaCount: 3

# Simplified persistent volumes (recommended for deploy)
simpleVolumes:
  - mountPath: "/app/uploads"
    size: "50Gi"
    storageClass: "fast-ssd"
    accessModes: ["ReadWriteMany"]  # Shared across pods
    name: "shared-uploads"

  - mountPath: "/app/cache"
    size: "10Gi" 
    storageClass: "standard"
    accessModes: ["ReadWriteMany"]
    name: "shared-cache"

# Mount external ConfigMap
simpleMounts:
  - mountPath: "/etc/app-config"
    configMap: "web-app-config"
```

### 2. Deploy Chart - External PVC

```yaml
# values-deploy-external.yaml
app:
  name: "web-app"

# Use existing PVC
volumeMounts:
  - name: shared-data
    mountPath: /app/data
  - name: logs
    mountPath: /var/log/app

volumes:
  - name: shared-data
    persistentVolumeClaim:
      claimName: existing-shared-pvc
  - name: logs
    persistentVolumeClaim:
      claimName: existing-logs-pvc
```

### 3. STS Chart - Per-Pod Persistent Storage

```yaml
# values-sts-database.yaml
app:
  name: "postgres-cluster"

replicaCount: 3

# StatefulSet volume claim templates (each pod gets own storage)
statefulset:
  serviceName: "postgres-headless"
  volumeClaimTemplates:
    - metadata:
        name: postgres-data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: "fast-ssd"
        resources:
          requests:
            storage: 100Gi
    
    - metadata:
        name: postgres-wal
      spec:
        accessModes: ["ReadWriteOnce"] 
        storageClassName: "ultra-fast"
        resources:
          requests:
            storage: 20Gi

# Volume mounts for StatefulSet volumes
volumeMounts:
  - name: postgres-data
    mountPath: /var/lib/postgresql/data
  - name: postgres-wal
    mountPath: /var/lib/postgresql/wal

# Optional: Shared config volume
volumes:
  - name: postgres-config
    configMap:
      name: postgres-config

# Mount the shared config
simpleMounts:
  - mountPath: "/etc/postgresql"
    configMap: "postgres-config"
```

### 4. STS Chart - Mixed Storage Strategy

```yaml
# values-sts-mixed.yaml
app:
  name: "elasticsearch"

replicaCount: 3

# Per-pod data storage
statefulset:
  volumeClaimTemplates:
    - metadata:
        name: es-data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: "fast-ssd"
        resources:
          requests:
            storage: 200Gi

# Per-pod data mount
volumeMounts:
  - name: es-data
    mountPath: /usr/share/elasticsearch/data

# Shared configurations and certificates
simpleVolumes:
  - mountPath: "/usr/share/elasticsearch/config/certs"
    size: "1Gi"
    storageClass: "standard"
    accessModes: ["ReadWriteMany"]
    name: "shared-certs"

simpleMounts:
  - mountPath: "/usr/share/elasticsearch/config"
    configMap: "elasticsearch-config"
  - mountPath: "/usr/share/elasticsearch/config/secrets"
    secret: "elasticsearch-secrets"
```

### 5. Deploy Chart - Temporary Storage

```yaml
# values-deploy-temp.yaml
app:
  name: "batch-processor"

# Temporary storage that doesn't need persistence
volumeMounts:
  - name: temp-data
    mountPath: /tmp/processing
  - name: cache
    mountPath: /app/cache

volumes:
  - name: temp-data
    emptyDir:
      sizeLimit: "10Gi"
  - name: cache
    emptyDir:
      sizeLimit: "5Gi"
```

## Storage Class Examples

Different storage classes for different use cases:

```yaml
# Fast SSD for databases
storageClass: "fast-ssd"

# Standard HDD for logs/backups  
storageClass: "standard"

# Ultra-fast NVMe for high-performance workloads
storageClass: "ultra-fast"

# Network storage for shared access
storageClass: "nfs-client"
```

## Access Modes

Choose the right access mode:

```yaml
# Single pod access (StatefulSets)
accessModes: ["ReadWriteOnce"]

# Multiple pods, same node
accessModes: ["ReadWriteOnce"]

# Multiple pods, different nodes (requires NFS/similar)
accessModes: ["ReadWriteMany"]

# Read-only shared access
accessModes: ["ReadOnlyMany"]
```

## Best Practices

### For Deploy Charts
- Use `ReadWriteMany` for shared storage across replicas
- Prefer `simpleVolumes` for straightforward persistent storage
- Use `emptyDir` for temporary/cache storage
- Create external PVCs for large shared datasets

### For STS Charts  
- Use `volumeClaimTemplates` for per-pod persistent storage
- Use `ReadWriteOnce` for database storage (better performance)
- Combine with shared volumes for configurations
- Plan storage size carefully (StatefulSet PVCs are harder to resize)

### General
- Choose appropriate storage classes for performance needs
- Use `simpleMounts` for ConfigMaps and Secrets
- Monitor storage usage and plan for growth
- Consider backup strategies for persistent data