# Volume Mount Examples for ConfigMaps and Secrets

This directory contains comprehensive examples demonstrating all possible configurations for mounting ConfigMaps and Secrets as volumes in your Helm charts.

## 📁 Available Example Files

### 1. `volume-mount-values.yaml`
**Basic examples** - Simple use cases to get started
- Basic ConfigMap and Secret mounting
- Single file mounts with `subPath`
- Using existing resources
- Different permission settings

### 2. `comprehensive-volume-examples.yaml`
**Complete feature showcase** - Demonstrates ALL possible configurations
- All `volumeConfigMaps` options
- All `volumeSecrets` options  
- Every parameter and setting available
- Complex multi-file scenarios

### 3. `microservice-volume-examples.yaml`
**Microservice patterns** - Real-world backend service examples
- Application configuration
- Database credentials
- API keys and external service credentials
- JWT and encryption keys
- mTLS certificates
- Monitoring and observability setup

### 4. `web-app-volume-examples.yaml`
**Web application patterns** - Frontend and web server examples
- Nginx configuration
- SPA routing setup
- SSL/TLS certificates
- Static asset configuration
- Error pages
- CORS and security headers

### 5. `data-processing-volume-examples.yaml`
**Data processing patterns** - ETL, ML, and analytics examples
- ETL pipeline configuration
- Data quality rules
- ML model configurations
- Database connections for analytics
- External API integrations
- Message queue configurations

### 6. `existing-resources-examples.yaml`
**External resource references** - Using existing ConfigMaps/Secrets
- Resources created by other Helm charts
- Resources created by Kubernetes operators
- Resources created by GitOps systems
- Resources created by external secret management

## 🔧 Configuration Options

### volumeConfigMaps
Configure mounting of ConfigMaps as volumes:

```yaml
volumeConfigMaps:
  enabled: true|false  # Enable/disable ConfigMap volume mounting
  items:
    - name: "config-name"                    # Required: Name for the volume
      mountPath: "/path/to/mount"            # Required: Where to mount in container
      existingConfigMap: "existing-name"    # Optional: Use existing ConfigMap
      data:                                  # Optional: Create new ConfigMap with this data
        "file1.yaml": "content..."
        "file2.json": "content..."
      subPath: "file1.yaml"                  # Optional: Mount only specific file
      readOnly: true|false                   # Optional: Mount as read-only (default: false)
      defaultMode: 0644                      # Optional: File permissions (default: 0644)
```

### volumeSecrets  
Configure mounting of Secrets as volumes:

```yaml
volumeSecrets:
  enabled: true|false  # Enable/disable Secret volume mounting
  items:
    - name: "secret-name"                    # Required: Name for the volume
      mountPath: "/path/to/mount"            # Required: Where to mount in container  
      existingSecret: "existing-name"       # Optional: Use existing Secret
      stringData:                           # Optional: Create new Secret with this data
        "username": "value"
        "password": "value"
      subPath: "username"                   # Optional: Mount only specific key
      readOnly: true|false                  # Optional: Mount as read-only (default: false)
      defaultMode: 0400                     # Optional: File permissions (default: varies)
```

## 📋 Common Use Cases

### 1. **Application Configuration**
Mount configuration files for your application:
```yaml
volumeConfigMaps:
  enabled: true
  items:
    - name: "app-config"
      mountPath: "/etc/config"
      data:
        "config.yaml": |
          app:
            name: myapp
            debug: false
```

### 2. **Database Credentials**
Mount database passwords and connection strings:
```yaml
volumeSecrets:
  enabled: true
  items:
    - name: "db-creds"
      mountPath: "/var/secrets/db"
      readOnly: true
      defaultMode: 0400
      stringData:
        "username": "dbuser"
        "password": "dbpass"
```

### 3. **Single File Mounting**
Mount a specific file from a ConfigMap/Secret:
```yaml
volumeConfigMaps:
  enabled: true
  items:
    - name: "nginx-config"
      mountPath: "/etc/nginx/nginx.conf"
      subPath: "nginx.conf"  # Only mount this file
      data:
        "nginx.conf": "nginx config content..."
```

### 4. **Existing Resources**
Reference ConfigMaps/Secrets created outside of this chart:
```yaml
volumeConfigMaps:
  enabled: true
  items:
    - name: "external-config"
      mountPath: "/etc/external"
      existingConfigMap: "shared-config"  # Created by another system
```

### 5. **Multiple Configurations**
Mount multiple ConfigMaps and Secrets:
```yaml
volumeConfigMaps:
  enabled: true
  items:
    - name: "app-config"
      mountPath: "/etc/app"
      data: {...}
    - name: "feature-flags"
      mountPath: "/etc/features"
      data: {...}

volumeSecrets:
  enabled: true
  items:
    - name: "api-keys"
      mountPath: "/var/secrets/apis"
      stringData: {...}
    - name: "certificates"
      mountPath: "/etc/certs"
      stringData: {...}
```

## 🔒 Security Best Practices

### File Permissions
- **ConfigMaps**: Default `0644` (readable by all)
- **Secrets**: Use restrictive permissions like `0400` or `0440`
- **Certificates**: Public certs can be `0444`, private keys should be `0400`

### Read-Only Mounts
Always mount secrets as read-only:
```yaml
volumeSecrets:
  enabled: true
  items:
    - name: "sensitive-data"
      mountPath: "/var/secrets"
      readOnly: true  # Always recommended for secrets
```

### Separate Sensitive Data
Keep different types of secrets in separate mounts:
```yaml
# Database credentials
- name: "db-creds"
  mountPath: "/var/secrets/db"
  
# API keys  
- name: "api-keys"
  mountPath: "/var/secrets/apis"
  
# TLS certificates
- name: "tls-certs"
  mountPath: "/etc/tls"
```

## 🧪 Testing Your Configuration

Test your chart with different examples:

```bash
# Test basic functionality
helm template test pfnapp/deploy -f volume-mount-values.yaml --set deploymentType=deployment

# Test comprehensive features
helm template test pfnapp/deploy -f comprehensive-volume-examples.yaml --set deploymentType=deployment

# Test specific use case
helm template test pfnapp/deploy -f microservice-volume-examples.yaml --set deploymentType=deployment

# Validate chart syntax
helm lint pfnapp/deploy
```

## 🔍 Debugging

If volume mounts aren't working:

1. **Check the condition**: Ensure `volumeConfigMaps.enabled=true` or `volumeSecrets.enabled=true`
2. **Verify template output**: Use `helm template` to see generated YAML
3. **Check resource creation**: Verify ConfigMaps/Secrets are created
4. **Validate paths**: Ensure mount paths don't conflict
5. **Check permissions**: Verify file permissions are correct

## 📖 Related Documentation

- [Kubernetes ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Helm Chart Development](https://helm.sh/docs/chart_best_practices/)
- [Volume Mounts](https://kubernetes.io/docs/concepts/storage/volumes/)

## 🚀 Next Steps

1. **Start with basic examples** to understand the concepts
2. **Adapt to your use case** using the appropriate pattern file
3. **Test thoroughly** in your development environment
4. **Follow security best practices** for production deployments
5. **Monitor and maintain** your configurations over time