# Deploy Chart

A Helm chart for deploying **stateless applications** as Kubernetes Deployments.

## Overview

This chart is designed for stateless workloads that can run multiple replicas sharing storage and configuration. Perfect for web applications, APIs, microservices, and other horizontally scalable services.

## Key Features

- **Deployment Workloads**: Optimized for stateless applications
- **Horizontal Pod Autoscaling**: Built-in HPA support
- **Flexible Ingress**: 4 different ingress configuration patterns
- **Multiple Storage Options**: Standard volumes, simple mounts, and simplified persistent volumes
- **Environment Management**: ConfigMap, Secret, and external references
- **Health Checks**: Standard and simplified probe configurations
- **Security**: Pod and container security contexts

## Quick Start

### Basic Web Application

```yaml
# values.yaml
app:
  name: "my-web-app"

image:
  repository: "nginx"
  tag: "1.21"

service:
  port: 80

simpleIngress:
  - enabled: true
    domain: "myapp.example.com"
    className: "nginx"
    tls: true
    certManager:
      enabled: true
      issuer: "letsencrypt"

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

### Install

```bash
helm install my-app pfnapp/deploy -f values.yaml
```

## Configuration

All configuration is done through the `values.yaml` file. Below are the complete configuration options:

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

### Service Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.enabled` | Enable service creation | `true` |
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `service.targetPort` | Target port on pods | `80` |
| `service.annotations` | Service annotations | `{}` |
| `service.ports` | Multiple ports configuration | `[]` |

### Ingress Configuration

The chart supports **4 different ingress patterns**:

#### 1. Legacy Single Ingress

```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
  hosts:
    - host: myapp.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: myapp-tls
      hosts:
        - myapp.example.com
```

#### 2. Multiple Named Ingresses

```yaml
ingresses:
  public:
    enabled: true
    className: "nginx"
    hosts:
      - host: myapp.example.com
        paths:
          - path: /
            pathType: Prefix
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

#### 3. Domain-Based Ingresses (Auto-Generated Names)

```yaml
ingressDomains:
  - enabled: true
    host: "myapp.example.com"
    className: "haproxy"
    tls: true
    tlsSecret: "myapp-example-com-tls"  # Optional
    paths:
      - path: /
        pathType: Prefix
```

#### 4. Simplified Ingress (Recommended)

```yaml
simpleIngress:
  - enabled: true
    domain: "myapp.example.com"  # Auto-generates host and TLS secret
    className: "haproxy"
    tls: true
    certManager:
      enabled: true
      issuer: "letsencrypt"
    externalDns:
      enabled: true
      target: "ingress.example.com"
      cloudflareProxied: false
```

### Environment Variables

#### Helm-Managed ConfigMap

```yaml
configMap:
  enabled: true
  data:
    DATABASE_URL: "postgres://localhost:5432/myapp"
    REDIS_URL: "redis://localhost:6379"
```

#### Helm-Managed Secret

```yaml
secret:
  enabled: true
  data:
    API_KEY: "bXlfc2VjcmV0X2FwaV9rZXk="  # base64 encoded
    DB_PASSWORD: "c2VjcmV0cGFzcw=="
```

#### External References

```yaml
env:
  # Direct values
  - name: NODE_ENV
    value: "production"
  
  # From external ConfigMap
  - name: CONFIG_VALUE
    valueFrom:
      configMapKeyRef:
        name: external-config
        key: config-key
        optional: false
  
  # From external Secret
  - name: SECRET_VALUE
    valueFrom:
      secretKeyRef:
        name: external-secret
        key: secret-key
        optional: true

# Load all keys from external sources
envFrom:
  - configMapRef:
      name: common-config
      optional: false
  - secretRef:
      name: app-secrets
      optional: true
```

### Storage & Volumes

#### Simplified Persistent Volumes (Recommended)

```yaml
simpleVolumes:
  - mountPath: "/app/uploads"
    size: "50Gi"
    storageClass: "fast-ssd"
    accessModes: ["ReadWriteMany"]  # Shared across pods
    name: "uploads-storage"
  
  - mountPath: "/app/cache"
    size: "10Gi"
    storageClass: "standard"
```

#### Simple File Mounts

```yaml
simpleMounts:
  - mountPath: "/etc/app-config"
    configMap: "app-config"
  - mountPath: "/etc/secrets"
    secret: "app-secrets"
```

#### Standard Kubernetes Volumes

```yaml
volumeMounts:
  - name: data-volume
    mountPath: /app/data
  - name: config-volume
    mountPath: /etc/config
    readOnly: true

volumes:
  - name: data-volume
    persistentVolumeClaim:
      claimName: existing-pvc
  - name: config-volume
    configMap:
      name: app-config
```

### Resource Management

```yaml
resources:
  limits:
    cpu: "1000m"
    memory: "1Gi"
  requests:
    cpu: "100m"
    memory: "128Mi"
```

### Health Checks

#### Simplified Probes (Recommended)

```yaml
simpleLivenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10

simpleReadinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5

simpleStartupProbe:
  httpGet:
    path: /startup
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5
  failureThreshold: 30
```

#### Standard Probes

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: http
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3
```

### Auto-scaling

```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  # targetMemoryUtilizationPercentage: 80
```

### Security Settings

#### Pod Security Context

```yaml
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
```

#### Container Security Context

```yaml
securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  runAsNonRoot: true
  runAsUser: 1000
  capabilities:
    drop:
      - ALL
```

#### Service Account

```yaml
serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789:role/my-role
  labels:
    component: terminal-service
  automountServiceAccountToken: true
  name: "custom-service-account"
```

If you skip this block, the chart automatically creates a service account (named after the release) whenever RBAC is enabled, applying the standard chart labels.

### RBAC

#### Standard configuration

```yaml
rbac:
  enabled: true
  kind: ClusterRole
  rules:
    - apiGroups: [""]
      resources: ["pods/exec"]
      verbs: ["create"]
    - apiGroups: [""]
      resources: ["pods"]
      verbs: ["get", "list", "watch"]
    - apiGroups: ["apps"]
      resources: ["deployments", "replicasets"]
      verbs: ["get", "list", "watch"]
    - apiGroups: [""]
      resources: ["services"]
      verbs: ["get", "list", "watch"]
    - apiGroups: [""]
      resources: ["events"]
      verbs: ["get", "list", "watch"]
    - apiGroups: [""]
      resources: ["configmaps", "secrets"]
      verbs: ["get", "list"]
    - apiGroups: [""]
      resources: ["namespaces"]
      verbs: ["get", "list"]
  namespaceRole:
    enabled: true
    rules:
      - apiGroups: [""]
        resources: ["pods", "pods/exec", "pods/attach", "pods/log", "pods/status"]
        verbs: ["*"]
      - apiGroups: [""]
        resources: ["configmaps", "secrets"]
        verbs: ["*"]
      - apiGroups: [""]
        resources: ["services", "endpoints"]
        verbs: ["*"]
```

When enabled, the chart automatically names the RBAC objects using the release fullname, applies standard labels, and binds the role to the service account configured for the workload (either managed by the chart or specified via `serviceAccount.name`).

Namespace-level roles are optional. Enable `rbac.namespaceRole` to create a Role/RoleBinding scoped to the release namespace (useful when the workload needs elevated permissions in its own namespace while keeping cluster-wide discovery permissions separate).

#### Multiple roles (list syntax)

To define more than one RBAC object, replace the map with an array:

```yaml
rbac:
  - enabled: true
    kind: ClusterRole
    name: pfn-terminal-api-role
    bindingName: pfn-terminal-api-binding
    rules:
      - apiGroups: [""]
        resources: ["pods", "pods/exec", "pods/status", "pods/log"]
        verbs: ["get", "list", "watch", "create"]
  - enabled: true
    kind: Role
    namespace: pfnapp-dev-alesha
    name: pfn-terminal-namespace-role
    bindingName: pfn-terminal-namespace-binding
    rules:
      - apiGroups: [""]
        resources: ["pods", "pods/exec", "pods/attach", "pods/log", "pods/status"]
        verbs: ["*"]
    subjects:
      - kind: ServiceAccount
        name: pfn-terminal-service
        namespace: pfnapp-dev-alesha
```

Each element defaults to binding against the chart-managed service account unless you supply custom `subjects`. Optional fields like `bindingEnabled`, `bindingKind`, `labels`, and `annotations` are also supported per entry.


### Networking

```yaml
containerPorts:
  - containerPort: 8080
    name: http
  - containerPort: 9090
    name: metrics
```

### Scheduling & Placement

```yaml
nodeSelector:
  kubernetes.io/arch: amd64

tolerations:
  - key: "node-type"
    operator: "Equal"
    value: "spot"
    effect: "NoSchedule"

affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
              - key: app.kubernetes.io/name
                operator: In
                values:
                  - myapp
          topologyKey: kubernetes.io/hostname
```

### Logging Configuration

```yaml
logging:
  enabled: true  # Adds "-service" suffix and logging tolerations
```

### Pod Annotations

```yaml
podAnnotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "8080"
  prometheus.io/path: "/metrics"
```

## Examples

See [VOLUMES.md](../../VOLUMES.md) for detailed volume configuration examples.

### Basic API Service

```yaml
app:
  name: "api-service"

image:
  repository: "mycompany/api"
  tag: "v1.2.3"

replicaCount: 3

service:
  port: 8080
  targetPort: 8080

containerPorts:
  - containerPort: 8080
    name: http

simpleLivenessProbe:
  httpGet:
    path: /health
    port: 8080

simpleReadinessProbe:
  httpGet:
    path: /ready
    port: 8080

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 20

resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"

env:
  - name: PORT
    value: "8080"
  - name: NODE_ENV
    value: "production"
```

## Migration from Combined Chart

If migrating from the previous combined chart:

1. Remove `deploymentType: "deployment"` from your values
2. Use `pfnapp/deploy` instead of `pfnapp/deploy-old`
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

- [STS Chart](../sts/) - For StatefulSet workloads
- [Volume Examples](../../VOLUMES.md) - Storage configuration examples
- [Migration Guide](../../MIGRATION.md) - Upgrade from combined chart
