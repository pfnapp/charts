# Deploy Helm Chart

A dynamic Helm chart for deploying applications with configurable deployment types, environment variables, ingress configurations, and logging support.

## Overview

This chart provides a flexible way to deploy applications to Kubernetes with support for:
- **Deployment Types**: Standard Deployment or StatefulSet
- **Multiple Ingress Options**: Single, multiple, domain-based, and simplified configurations
- **Environment Variables**: ConfigMaps, Secrets, and external references
- **Health Checks**: Standard and simplified probe configurations
- **Auto-scaling**: Horizontal Pod Autoscaler support
- **Security**: Pod and container security contexts
- **Storage**: Persistent volumes and simple mounts

## Installation

```bash
# Add the repository
helm repo add pfnapp https://github.com/pfnapp/charts

# Install the chart
helm install my-app pfnapp/deploy -f values.yaml
```

## Configuration

The following table lists the configurable parameters and their default values.

### Application Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `app.name` | Application name | `"myapp"` |
| `app.version` | Application version | `"latest"` |
| `deploymentType` | Deployment type: "deployment" or "statefulset" | `"deployment"` |
| `replicaCount` | Number of replicas | `1` |

### Image Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Container image repository | `"nginx"` |
| `image.tag` | Container image tag | `"latest"` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `imagePullSecrets` | Image pull secrets | `[]` |

### Service Account

| Parameter | Description | Default |
|-----------|-------------|---------|
| `serviceAccount.create` | Create service account | `true` |
| `serviceAccount.annotations` | Service account annotations | `{}` |
| `serviceAccount.name` | Service account name (auto-generated if empty) | `""` |

### Security Contexts

| Parameter | Description | Default |
|-----------|-------------|---------|
| `podSecurityContext` | Pod security context | `{}` |
| `securityContext` | Container security context | `{}` |
| `podAnnotations` | Pod annotations | `{}` |

**Example:**
```yaml
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1001
  fsGroup: 2000

securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 1001
  capabilities:
    drop:
    - ALL
```

### Resources and Scheduling

| Parameter | Description | Default |
|-----------|-------------|---------|
| `resources` | Resource limits and requests | `{}` |
| `nodeSelector` | Node selector | `{}` |
| `tolerations` | Tolerations for taints | `[]` |
| `affinity` | Affinity rules | `{}` |

**Example:**
```yaml
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

nodeSelector:
  disktype: ssd
  kubernetes.io/arch: amd64
```

### Auto-scaling

| Parameter | Description | Default |
|-----------|-------------|---------|
| `autoscaling.enabled` | Enable HPA | `false` |
| `autoscaling.minReplicas` | Minimum replicas | `1` |
| `autoscaling.maxReplicas` | Maximum replicas | `100` |
| `autoscaling.targetCPUUtilizationPercentage` | Target CPU utilization | `80` |

### Service Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.enabled` | Enable service | `true` |
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `service.targetPort` | Target port | `80` |
| `service.annotations` | Service annotations | `{}` |

### Container Ports

| Parameter | Description | Default |
|-----------|-------------|---------|
| `containerPorts` | Container ports configuration | `[{containerPort: 80, name: "http"}]` |

## Health Checks

### Standard Probes

Configure detailed health checks:

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: http
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /ready
    port: http
  initialDelaySeconds: 5
  periodSeconds: 5

startupProbe:
  httpGet:
    path: /health
    port: http
  initialDelaySeconds: 10
  periodSeconds: 5
  failureThreshold: 30
```

### Simplified Probes

For quick setup, just provide the path:

```yaml
# Minimal configuration - uses defaults
simpleLivenessProbe:
  httpGet:
    path: "/health"

simpleReadinessProbe:
  httpGet:
    path: "/ready"

simpleStartupProbe:
  httpGet:
    path: "/health"
```

**Simplified Probe Defaults:**
- **Liveness**: initialDelaySeconds=30, periodSeconds=10, timeoutSeconds=5, failureThreshold=3
- **Readiness**: initialDelaySeconds=5, periodSeconds=5, timeoutSeconds=3, failureThreshold=3
- **Startup**: initialDelaySeconds=10, periodSeconds=5, timeoutSeconds=3, failureThreshold=30
- **Port**: defaults to "http" if not specified

## Environment Variables

### Helm-Managed ConfigMap/Secret

```yaml
configMap:
  enabled: true
  data:
    DATABASE_HOST: "postgres.example.com"
    DATABASE_PORT: "5432"
    LOG_LEVEL: "info"

secret:
  enabled: true
  data:
    DATABASE_PASSWORD: "c2VjcmV0cGFzcw=="  # base64 encoded
    API_TOKEN: "dG9rZW4xMjM="              # base64 encoded
```

### External References

```yaml
env:
  # Direct value
  - name: "ENVIRONMENT"
    value: "production"
  
  # From external ConfigMap
  - name: "DATABASE_URL"
    valueFrom:
      configMapKeyRef:
        name: "database-config"
        key: "url"
        optional: false
  
  # From external Secret
  - name: "API_KEY"
    valueFrom:
      secretKeyRef:
        name: "api-secrets"
        key: "key"
        optional: false

# Load all keys from external ConfigMap/Secret
envFrom:
  - configMapRef:
      name: "app-config"
      optional: false
  - secretRef:
      name: "app-secrets"
      optional: false
```

## Ingress Configuration

### 1. Single Ingress (Legacy)

```yaml
ingress:
  enabled: true
  className: "haproxy"
  annotations:
    haproxy.org/load-balance: "roundrobin"
  hosts:
    - host: chart-example.local
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: example-tls
      hosts:
        - chart-example.local
```

### 2. Multiple Ingresses (Advanced)

```yaml
ingresses:
  public:
    enabled: true
    className: "haproxy"
    annotations:
      haproxy.org/load-balance: "roundrobin"
    hosts:
      - host: myapp.example.com
        paths:
          - path: /
            pathType: Prefix
    tls:
      - secretName: myapp-tls
        hosts:
          - myapp.example.com
  
  admin:
    enabled: true
    className: "nginx"
    annotations:
      nginx.ingress.kubernetes.io/auth-type: basic
    hosts:
      - host: admin.myapp.example.com
        paths:
          - path: /admin
            pathType: Prefix
```

### 3. Domain-Based Ingresses

```yaml
ingressDomains:
  - enabled: true
    host: "myapp.example.com"
    className: "haproxy"
    tls: true
    tlsSecret: "myapp-example-com-tls"
    annotations:
      haproxy.org/load-balance: "roundrobin"
    paths:
      - path: /
        pathType: Prefix
```

### 4. Simplified Ingress (Recommended)

Automated setup with Let's Encrypt and External DNS:

```yaml
simpleIngress:
  - enabled: true
    domain: "myapp.example.com"
    className: "haproxy"
    tls: true
    certManager:
      enabled: true
      issuer: "letsencrypt-prod"
    externalDns:
      enabled: true
      target: "cname.example.com"
      cloudflareProxied: false
```

## Storage and Volumes

### Standard Volumes

```yaml
volumes:
  - name: config-volume
    configMap:
      name: my-config
  - name: data-volume
    persistentVolumeClaim:
      claimName: data-pvc

volumeMounts:
  - name: config-volume
    mountPath: /etc/config
    readOnly: true
  - name: data-volume
    mountPath: /data
```

### Simple Mounts

Quick ConfigMap/Secret mounting:

```yaml
simpleMounts:
  - mountPath: "/etc/config"
    configMap: "my-app-config"
  - mountPath: "/etc/secrets"
    secret: "my-app-secrets"
```

### Simple Volumes

Quick persistent volume setup - just specify path, size, and storage class:

```yaml
simpleVolumes:
  # Minimal configuration with defaults
  - mountPath: "/data"
    size: "10Gi"
    storageClass: "fast-ssd"
  
  # With custom access modes
  - mountPath: "/cache"
    size: "5Gi"
    storageClass: "standard"
    accessModes: ["ReadWriteMany"]
    name: "shared-cache"
```

**Simple Volume Features:**
- **Automatic PVC Creation**: For deployments, creates PersistentVolumeClaims automatically
- **StatefulSet Integration**: For StatefulSets, adds to volumeClaimTemplates
- **Default Access Mode**: Uses `ReadWriteOnce` if not specified
- **Auto-naming**: Generates volume names if not provided
- **Flexible**: Works with both deployment and StatefulSet types

### StatefulSet Configuration

```yaml
deploymentType: "statefulset"
statefulset:
  serviceName: ""  # Auto-generated if empty
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: "fast-ssd"
        resources:
          requests:
            storage: 10Gi
```

## Logging Configuration

```yaml
logging:
  enabled: true
  # When enabled, appends "-service" to deployment name and adds log taints
```

## Examples

### Basic Web Application

```yaml
app:
  name: "my-web-app"
  version: "1.0.0"

image:
  repository: "nginx"
  tag: "1.21"

service:
  port: 80
  targetPort: 80

simpleLivenessProbe:
  httpGet:
    path: "/"

simpleReadinessProbe:
  httpGet:
    path: "/"

simpleIngress:
  - enabled: true
    domain: "myapp.example.com"
    className: "nginx"
    tls: true
    certManager:
      enabled: true
      issuer: "letsencrypt-prod"
```

### Database Application with StatefulSet

```yaml
app:
  name: "postgres-db"

deploymentType: "statefulset"

image:
  repository: "postgres"
  tag: "13"

service:
  port: 5432
  targetPort: 5432

secret:
  enabled: true
  data:
    POSTGRES_PASSWORD: "cG9zdGdyZXNwYXNz"  # "postgrespass" base64

# Using simplified volumes instead of manual volumeClaimTemplates
simpleVolumes:
  - mountPath: "/var/lib/postgresql/data"
    size: "20Gi"
    storageClass: "fast-ssd"
    name: "postgres-data"

resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### Microservice with External Dependencies

```yaml
app:
  name: "api-service"

image:
  repository: "myregistry/api-service"
  tag: "v1.2.3"

env:
  - name: "SERVICE_PORT"
    value: "8080"
  - name: "DATABASE_URL"
    valueFrom:
      secretKeyRef:
        name: "database-secrets"
        key: "url"

envFrom:
  - configMapRef:
      name: "shared-config"

containerPorts:
  - containerPort: 8080
    name: http

simpleLivenessProbe:
  httpGet:
    path: "/health"
    port: "http"

simpleReadinessProbe:
  httpGet:
    path: "/ready"
    port: "http"

resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "200m"

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

## Best Practices

1. **Use Simplified Configurations**: Start with `simpleIngress` and `simpleLivenessProbe` for quick setup
2. **Resource Limits**: Always set resource requests and limits
3. **Health Checks**: Configure appropriate health checks for your application
4. **Security**: Use non-root containers and read-only root filesystems when possible
5. **Secrets**: Never commit secrets to Git - use external secret management
6. **Labels**: Leverage Helm's automatic labeling for resource management

## Troubleshooting

### Common Issues

1. **Probe Failures**: Check if your application responds on the configured health check paths
2. **Image Pull Errors**: Verify `imagePullSecrets` are configured for private registries
3. **Ingress Not Working**: Ensure the ingress controller is installed and className is correct
4. **Resource Constraints**: Check if resource limits are preventing pod startup

### Debugging Commands

```bash
# Check pod status
kubectl get pods -l app.kubernetes.io/instance=my-app

# View pod logs
kubectl logs -l app.kubernetes.io/instance=my-app

# Describe pod for events
kubectl describe pod <pod-name>

# Check ingress status
kubectl get ingress -l app.kubernetes.io/instance=my-app
```

## Contributing

This chart is maintained by the pfnapp team. For issues and contributions, please visit the [GitHub repository](https://github.com/pfnapp/charts).