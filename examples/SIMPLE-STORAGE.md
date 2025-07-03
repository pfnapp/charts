# Simple Storage Feature

The `simpleStorage` feature provides an ultra-simplified way to configure persistent storage for both Deploy and StatefulSet charts with minimal configuration.

## Overview

The `simpleStorage` feature is designed to be **even simpler** than `simpleVolumes`, requiring only 3 basic parameters:

- **`path`** - Where to mount the storage in the container
- **`size`** - How much storage to allocate  
- **`class`** - Which storage class to use

Everything else is handled automatically with sensible defaults optimized for each chart type.

## Key Differences from simpleVolumes

| Feature | simpleStorage | simpleVolumes |
|---------|---------------|---------------|
| **Required Fields** | 3 (path, size, class) | 3 (mountPath, size, storageClass) |
| **Field Names** | Shorter (`path`, `class`) | Longer (`mountPath`, `storageClass`) |
| **Auto-naming** | Smart path-based naming | Index-based naming |
| **Access Modes** | Chart-optimized defaults | Manual defaults |
| **Purpose** | Ultra-simple common cases | More flexible configuration |

## Usage Examples

### Deploy Chart (Shared Storage)

```yaml
# Ultra-simple shared storage for web apps
simpleStorage:
  - path: "/uploads"
    size: "50Gi" 
    class: "fast-ssd"
    # Creates: PVC "uploads" with ReadWriteMany (shared across pods)
  
  - path: "/app/cache"
    size: "10Gi"
    class: "standard"
    # Creates: PVC "app-cache" with ReadWriteMany
```

**What it creates:**
- External PersistentVolumeClaims with `ReadWriteMany` access (optimized for sharing across Deployment replicas)
- Auto-generated volume and volumeMount configurations
- Smart naming: `/uploads` → `uploads`, `/app/cache` → `app-cache`

### STS Chart (Per-Pod Storage)

```yaml
# Ultra-simple per-pod storage for databases
simpleStorage:
  - path: "/database"
    size: "100Gi"
    class: "fast-ssd"
    # Creates: volumeClaimTemplate "database" with ReadWriteOnce (per-pod)
  
  - path: "/var/log/app"
    size: "20Gi"
    class: "standard"
    # Creates: volumeClaimTemplate "var-log-app" with ReadWriteOnce
```

**What it creates:**
- StatefulSet volumeClaimTemplates with `ReadWriteOnce` access (each pod gets own storage)
- Auto-generated volumeMount configurations
- Smart naming: `/database` → `database`, `/var/log/app` → `var-log-app`

## Advanced Configuration

### Custom Names and Access Modes

```yaml
simpleStorage:
  # Override auto-generated name
  - path: "/data"
    size: "200Gi"
    class: "ultra-fast"
    name: "custom-data-volume"
  
  # Override access modes (Deploy chart)
  - path: "/shared"
    size: "100Gi"
    class: "nfs"
    accessModes: ["ReadWriteMany"]
  
  # Override access modes (STS chart)  
  - path: "/backup"
    size: "500Gi"
    class: "backup-storage"
    accessModes: ["ReadWriteOnce"]
```

## Complete Examples

### Web Application with Uploads (Deploy)

```yaml
app:
  name: "web-app"

image:
  repository: "nginx"
  tag: "latest"

replicaCount: 3

# Simple shared storage
simpleStorage:
  - path: "/var/www/uploads"
    size: "100Gi"
    class: "fast-ssd"
  
  - path: "/tmp/cache"
    size: "20Gi"
    class: "standard"

# Install
# helm install web-app pfnapp/deploy -f values.yaml
```

**Creates:**
- PVC `web-app-var-www-uploads` (100Gi, fast-ssd, ReadWriteMany)
- PVC `web-app-tmp-cache` (20Gi, standard, ReadWriteMany)
- volumeMounts automatically configured
- Shared across all 3 replicas

### PostgreSQL Cluster (STS)

```yaml
app:
  name: "postgres"

image:
  repository: "postgres"
  tag: "14"

replicaCount: 3

# Per-pod database storage
simpleStorage:
  - path: "/var/lib/postgresql/data"
    size: "200Gi"
    class: "fast-ssd"
    name: "postgres-data"
  
  - path: "/var/lib/postgresql/wal"
    size: "50Gi"
    class: "ultra-fast"
    name: "postgres-wal"

env:
  - name: POSTGRES_DB
    value: "myapp"

# Install
# helm install postgres pfnapp/sts -f values.yaml
```

**Creates:**
- volumeClaimTemplate `postgres-data` (200Gi, fast-ssd, ReadWriteOnce)
- volumeClaimTemplate `postgres-wal` (50Gi, ultra-fast, ReadWriteOnce)  
- Each of 3 pods gets own storage: postgres-0, postgres-1, postgres-2
- Total storage: 750Gi (250Gi × 3 pods)

## Auto-Naming Logic

The feature automatically generates storage names from paths:

| Path | Generated Name |
|------|----------------|
| `/data` | `data` |
| `/app/uploads` | `app-uploads` |
| `/var/log/app` | `var-log-app` |
| `/tmp/cache` | `tmp-cache` |
| `/` | `root` |

## Default Access Modes

| Chart Type | Default Access Mode | Reason |
|------------|-------------------|---------|
| **Deploy** | `ReadWriteMany` | Optimized for sharing across Deployment replicas |
| **STS** | `ReadWriteOnce` | Optimized for per-pod StatefulSet storage |

## Combining with Other Features

`simpleStorage` works alongside existing storage features:

```yaml
# Mix all storage types
simpleStorage:
  - path: "/database"
    size: "100Gi"
    class: "fast-ssd"

simpleVolumes:
  - mountPath: "/cache"
    size: "10Gi"
    storageClass: "standard"

simpleMounts:
  - mountPath: "/config"
    configMap: "app-config"

volumes:
  - name: custom-volume
    emptyDir: {}

volumeMounts:
  - name: custom-volume
    mountPath: /tmp
```

## Migration from simpleVolumes

Easy migration path:

```yaml
# OLD (simpleVolumes)
simpleVolumes:
  - mountPath: "/data"
    size: "100Gi"
    storageClass: "fast-ssd"
    accessModes: ["ReadWriteOnce"]
    name: "data-storage"

# NEW (simpleStorage)  
simpleStorage:
  - path: "/data"
    size: "100Gi"
    class: "fast-ssd"
    accessModes: ["ReadWriteOnce"]  # optional
    name: "data-storage"            # optional
```

## Benefits

### ✅ Pros
- **Minimal configuration** - Only 3 required fields
- **Chart-optimized defaults** - Different access modes for Deploy vs STS
- **Smart naming** - Path-based volume names  
- **Consistent API** - Same syntax across both charts
- **Backward compatible** - Works alongside existing features

### ⚠️ Considerations
- **Less flexible** than full Kubernetes volume configuration
- **Path-based naming** might not suit all use cases
- **Limited to PVC-based storage** (no configMap, secret, emptyDir, etc.)

## Best Practices

### For Deploy Charts
- Use `simpleStorage` for **shared persistent data** (uploads, shared cache)
- Consider `ReadWriteMany` storage classes (NFS, EFS, etc.)
- Plan for **horizontal scaling** across multiple pods

### For STS Charts  
- Use `simpleStorage` for **per-pod persistent data** (databases, logs)
- Use `ReadWriteOnce` storage classes for **better performance**
- Plan storage size carefully - **StatefulSet PVCs persist** after pod deletion

### Storage Classes
```yaml
# Performance tiers
class: "ultra-fast"   # NVMe SSD for databases
class: "fast-ssd"     # SSD for application data  
class: "standard"     # HDD for logs, backups
class: "nfs-client"   # Network storage for shared data
```

## Troubleshooting

### Common Issues

**1. Access Mode Compatibility**
```yaml
# ❌ Won't work with most storage providers
simpleStorage:
  - path: "/shared"
    class: "gp2"  # EBS only supports ReadWriteOnce
    accessModes: ["ReadWriteMany"]

# ✅ Use compatible storage
simpleStorage:
  - path: "/shared"  
    class: "efs"  # EFS supports ReadWriteMany
    accessModes: ["ReadWriteMany"]
```

**2. Storage Class Not Found**
```yaml
# Check available storage classes
kubectl get storageclass
```

**3. PVC Stuck in Pending**
```yaml
# Check events
kubectl describe pvc your-pvc-name
```

## Complete Reference

### Deploy Chart simpleStorage
- **Creates**: External PersistentVolumeClaims
- **Default Access Mode**: `ReadWriteMany`
- **Use Case**: Shared storage across Deployment replicas
- **Naming**: `<release>-<path-based-name>`

### STS Chart simpleStorage  
- **Creates**: StatefulSet volumeClaimTemplates
- **Default Access Mode**: `ReadWriteOnce`
- **Use Case**: Per-pod persistent storage
- **Naming**: `<path-based-name>` (no release prefix in volumeClaimTemplates)

This feature makes storage configuration as simple as possible while maintaining the flexibility to override defaults when needed.