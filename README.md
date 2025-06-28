# PFNApp Helm Charts

This repository contains Helm charts for deploying applications dynamically in Kubernetes clusters.

## Charts Overview

### 1. `pfnapp/deploy` - Dynamic Deployment Chart
A flexible chart that can deploy applications using either Deployment or StatefulSet with extensive configuration options.

### 2. `pfnapp/nginx` - Nginx Deployment
A simple Nginx deployment that uses the deploy chart as a dependency.

## Prerequisites

- Kubernetes cluster (v1.19+)
- Helm 3.x
- HAProxy Ingress Controller (for ingress functionality)

## Installation

### Using the Public Helm Repository

The charts are automatically published to GitHub Pages via GitHub Actions. You can add the repository and install charts directly:

1. **Add the Helm repository:**
   ```bash
   helm repo add pfnapp https://pfnapp.github.io/charts
   helm repo update
   ```

2. **Install the Nginx chart:**
   ```bash
   helm install my-nginx pfnapp/nginx
   ```

3. **Install the deploy chart:**
   ```bash
   helm install my-app pfnapp/deploy \
     --set image.repository=nginx \
     --set image.tag=latest
   ```

4. **Check the deployment:**
   ```bash
   kubectl get pods,svc,ingress
   ```

### Local Development

For local development and testing:

1. **Clone the repository:**
   ```bash
   git clone https://github.com/pfnapp/charts.git
   cd charts
   ```

2. **Update chart dependencies:**
   ```bash
   helm dependency update pfnapp/nginx
   ```

3. **Install the Nginx chart locally:**
   ```bash
   helm install my-nginx pfnapp/nginx
   ```

### Using the Dynamic Deploy Chart

The `pfnapp/deploy` chart can be used directly or as a dependency for other charts.

#### Direct Installation

1. **Install as Deployment:**
   ```bash
   helm install my-app pfnapp/deploy \
     --set image.repository=nginx \
     --set image.tag=latest \
     --set deploymentType=deployment
   ```

2. **Install as StatefulSet:**
   ```bash
   helm install my-stateful-app pfnapp/deploy \
     --set image.repository=postgres \
     --set image.tag=13 \
     --set deploymentType=statefulset \
     --set statefulset.serviceName=postgres-headless
   ```

#### Custom Values File

Create a `custom-values.yaml` file:

```yaml
# custom-values.yaml
deploymentType: "deployment"
replicaCount: 3

image:
  repository: "my-app"
  tag: "v1.0.0"
  pullPolicy: Always

service:
  enabled: true
  type: LoadBalancer
  port: 8080
  targetPort: 8080

ingress:
  enabled: true
  className: "haproxy"
  hosts:
    - host: myapp.example.com
      paths:
        - path: /
          pathType: Prefix

configMap:
  enabled: true
  data:
    DATABASE_URL: "postgresql://localhost:5432/mydb"
    REDIS_URL: "redis://localhost:6379"

secret:
  enabled: true
  data:
    API_KEY: "your-secret-api-key"
    DB_PASSWORD: "your-db-password"

logging:
  enabled: true

nodeSelector:
  node-type: "worker"

tolerations:
  - key: "logging"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

Install with custom values:
```bash
helm install my-custom-app pfnapp/deploy -f custom-values.yaml
```

## Configuration Options

### Deploy Chart Configuration

#### Deployment Types
- `deployment` - Standard Kubernetes Deployment
- `statefulset` - Kubernetes StatefulSet for stateful applications

#### Key Configuration Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `deploymentType` | Type of deployment (deployment/statefulset) | `deployment` |
| `replicaCount` | Number of replicas | `1` |
| `image.repository` | Container image repository | `nginx` |
| `image.tag` | Container image tag | `latest` |
| `service.enabled` | Enable service creation | `true` |
| `ingress.enabled` | Enable ingress creation | `false` |
| `configMap.enabled` | Enable ConfigMap for environment variables | `false` |
| `secret.enabled` | Enable Secret for sensitive environment variables | `false` |
| `logging.enabled` | Enable logging configuration (adds -service suffix and taints) | `false` |
| `nodeSelector` | Node selector for pod assignment | `{}` |
| `tolerations` | Tolerations for taints | `[]` |

#### Environment Variables

**From ConfigMap:**
```yaml
configMap:
  enabled: true
  data:
    ENV: "production"
    DEBUG: "false"
    DATABASE_URL: "postgresql://db:5432/myapp"
```

**From Secret:**
```yaml
secret:
  enabled: true
  data:
    API_KEY: "your-api-key"
    JWT_SECRET: "your-jwt-secret"
```

#### Logging Configuration

When `logging.enabled: true`:
- Deployment/StatefulSet name gets `-service` suffix
- Adds `enableLog: "true"` annotation to pods
- Automatically adds logging taint toleration:
  ```yaml
  tolerations:
    - key: "logging"
      operator: "Equal"
      value: "true"
      effect: "NoSchedule"
  ```

#### Node Selector and Taints

**Node Selection:**
```yaml
nodeSelector:
  node-type: "compute"
  zone: "us-west-1a"
```

**Tolerate Taints:**
```yaml
tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "compute"
    effect: "NoSchedule"
  - key: "gpu"
    operator: "Exists"
    effect: "NoExecute"
```

#### HAProxy Ingress

```yaml
ingress:
  enabled: true
  className: "haproxy"
  annotations:
    haproxy.org/load-balance: "roundrobin"
    haproxy.org/check: "true"
    haproxy.org/cookie-persistence: "SERVERID"
  hosts:
    - host: myapp.example.com
      paths:
        - path: /api
          pathType: Prefix
        - path: /health
          pathType: Exact
  tls:
    - secretName: myapp-tls
      hosts:
        - myapp.example.com
```

## Advanced Usage Examples

### 1. Web Application with Database

```yaml
# webapp-values.yaml
deploymentType: "deployment"
replicaCount: 3

image:
  repository: "mycompany/webapp"
  tag: "v2.1.0"

service:
  port: 3000
  targetPort: 3000

ingress:
  enabled: true
  hosts:
    - host: webapp.company.com
      paths:
        - path: /
          pathType: Prefix

configMap:
  enabled: true
  data:
    NODE_ENV: "production"
    PORT: "3000"
    DATABASE_HOST: "postgres-service"
    REDIS_HOST: "redis-service"

secret:
  enabled: true
  data:
    DATABASE_PASSWORD: "secure-db-password"
    JWT_SECRET: "jwt-signing-secret"
    API_KEY: "third-party-api-key"

logging:
  enabled: true

resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 20
  targetCPUUtilizationPercentage: 60
```

### 2. StatefulSet for Database

```yaml
# database-values.yaml
deploymentType: "statefulset"
replicaCount: 3

image:
  repository: "postgres"
  tag: "13-alpine"

service:
  port: 5432
  targetPort: 5432

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

configMap:
  enabled: true
  data:
    POSTGRES_DB: "myapp"
    POSTGRES_USER: "myapp_user"

secret:
  enabled: true
  data:
    POSTGRES_PASSWORD: "secure-password"

nodeSelector:
  node-type: "database"

tolerations:
  - key: "database"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"

resources:
  limits:
    cpu: 2000m
    memory: 4Gi
  requests:
    cpu: 1000m
    memory: 2Gi
```

### 3. Microservice with Logging

```yaml
# microservice-values.yaml
deploymentType: "deployment"
replicaCount: 2

image:
  repository: "mycompany/user-service"
  tag: "v1.5.2"

service:
  port: 8080
  targetPort: 8080

ingress:
  enabled: true
  hosts:
    - host: api.company.com
      paths:
        - path: /users
          pathType: Prefix

configMap:
  enabled: true
  data:
    SERVICE_NAME: "user-service"
    LOG_LEVEL: "info"
    METRICS_PORT: "9090"

logging:
  enabled: true  # This will add -service suffix and logging taints

nodeSelector:
  workload-type: "api"

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 200m
    memory: 256Mi
```

## Chart Management

### Update Dependencies
```bash
helm dependency update pfnapp/nginx
```

### List Installed Charts
```bash
helm list
```

### Upgrade a Release
```bash
helm upgrade my-nginx pfnapp/nginx -f custom-values.yaml
```

### Uninstall a Release
```bash
helm uninstall my-nginx
```

### Dry Run (Test Configuration)
```bash
helm install my-app pfnapp/deploy --dry-run --debug -f values.yaml
```

## Troubleshooting

### Common Issues

1. **Chart dependency issues:**
   ```bash
   helm dependency update pfnapp/nginx
   ```

2. **Check pod logs:**
   ```bash
   kubectl logs -l app.kubernetes.io/name=deploy
   ```

3. **Describe failing pods:**
   ```bash
   kubectl describe pods -l app.kubernetes.io/name=deploy
   ```

4. **Check ingress configuration:**
   ```bash
   kubectl describe ingress
   ```

### Validation

Test your configuration before deployment:
```bash
helm template my-app pfnapp/deploy -f values.yaml | kubectl apply --dry-run=client -f -
```

## Contributing

1. Make changes to the charts
2. Update the version in `Chart.yaml`
3. Test with `helm template` and `helm install --dry-run`
4. Update this README if adding new features

## GitHub Actions Integration

This repository uses GitHub Actions to automatically test, package, and publish Helm charts to GitHub Pages.

### Automatic Chart Publishing

The workflow automatically:
- **Tests charts** on pull requests with `helm lint` and `helm template`
- **Publishes charts** to GitHub Pages when pushed to main branch
- **Creates GitHub releases** for each chart version
- **Updates index.yaml** for the Helm repository

### GitHub Actions Workflows

1. **`.github/workflows/release.yml`** - Main workflow for testing and releasing charts
2. **`.github/workflows/pages.yml`** - GitHub Pages deployment workflow

### Repository Setup Requirements

To enable automatic chart publishing, ensure your GitHub repository has:

1. **GitHub Pages enabled** pointing to the `gh-pages` branch:
   - Go to Settings → Pages
   - Set Source to "Deploy from a branch"
   - Select `gh-pages` branch

2. **Workflow permissions** configured:
   - Go to Settings → Actions → General
   - Under "Workflow permissions", select "Read and write permissions"

3. **Branch protection** (recommended):
   - Protect the `main` branch
   - Require pull request reviews
   - Require status checks to pass

### Chart Versioning

When you want to release a new chart version:

1. **Update the version** in `pfnapp/[chart-name]/Chart.yaml`
2. **Commit and push** to main branch
3. **GitHub Actions automatically**:
   - Creates a GitHub release
   - Packages the chart
   - Updates the repository index
   - Publishes to GitHub Pages

### Manual Release (if needed)

If you need to manually trigger a release:

```bash
# Update chart dependencies
helm dependency update pfnapp/nginx

# Package charts manually
helm package pfnapp/deploy
helm package pfnapp/nginx

# Generate index
helm repo index . --url https://pfnapp.github.io/charts
```

### Monitoring Releases

- **GitHub Actions**: Check the Actions tab for workflow status
- **Releases**: View chart releases in the repository's Releases section
- **Repository**: Visit https://pfnapp.github.io/charts to see the published repository

### Repository Usage

Once published, users can add your repository:

```bash
# Add the repository
helm repo add pfnapp https://pfnapp.github.io/charts

# Search for charts
helm search repo pfnapp

# Install charts
helm install my-app pfnapp/deploy
helm install my-nginx pfnapp/nginx
```

## Support

For issues and questions:
- Create an issue in the repository
- Check the troubleshooting section above
- Review Kubernetes and Helm documentation
- Check GitHub Actions logs for CI/CD issues