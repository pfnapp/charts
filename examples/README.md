# PFNApp Helm Charts - Use Case Examples

This directory contains comprehensive examples demonstrating how to use the PFNApp Helm charts for various real-world scenarios.

## Chart Overview

- **pfnapp/deploy**: For stateless applications (web apps, APIs, microservices)
- **pfnapp/sts**: For stateful applications (databases, message queues, caches)

## Use Case Categories

### 🌐 Web Applications & APIs (pfnapp/deploy)
- [Simple Web Application](./web-app-simple.yaml) - Basic web app with ingress
- [API Gateway](./api-gateway.yaml) - API service with autoscaling and external config
- [Microservice with Database Connection](./microservice-db.yaml) - Service connecting to external database
- [Multi-Container Application](./multi-container-app.yaml) - App with sidecar containers

### 🗄️ Stateful Applications (pfnapp/sts)
- [PostgreSQL Database](./postgresql-sts.yaml) - Database with persistent storage
- [Redis Cache Cluster](./redis-cluster-sts.yaml) - Redis cluster with multiple instances
- [Message Queue](./message-queue-sts.yaml) - RabbitMQ or similar messaging system
- [Elasticsearch Node](./elasticsearch-sts.yaml) - Search engine with persistent data

### 🌍 Ingress Scenarios
- [Single Domain](./ingress-single.yaml) - Simple single domain setup
- [Multiple Services](./ingress-multiple.yaml) - Multiple services on different paths
- [Domain-Based Routing](./ingress-domain-based.yaml) - Route by hostname
- [SSL with Cert-Manager](./ingress-ssl-certmanager.yaml) - Automatic SSL certificates

### 💾 Storage Scenarios
- [Shared Storage](./storage-shared.yaml) - Multiple pods sharing storage (deploy)
- [Unique Storage](./storage-unique.yaml) - Each pod with own storage (sts)
- [Multiple Volumes](./storage-multiple.yaml) - Applications with multiple storage needs
- [External Storage](./storage-external.yaml) - Using existing PVCs

### ⚙️ Configuration Management
- [External Secrets](./config-external-secrets.yaml) - Using external secret management
- [ConfigMap Volumes](./config-configmap-volumes.yaml) - Mounting config files
- [Environment Variables](./config-env-vars.yaml) - Complex environment setup
- [Multi-Environment](./config-multi-env.yaml) - Dev/staging/prod configurations

### 🔧 Advanced Features
- [Health Checks](./health-checks-advanced.yaml) - Custom probe configurations
- [Resource Management](./resources-advanced.yaml) - CPU/memory limits and requests
- [Security Context](./security-advanced.yaml) - Security policies and service accounts
- [Monitoring Integration](./monitoring-setup.yaml) - Prometheus and logging setup

## Quick Start Guide

1. **Choose your chart**:
   - Use `pfnapp/deploy` for stateless applications
   - Use `pfnapp/sts` for stateful applications

2. **Select a use case** from the examples above that matches your needs

3. **Install the chart**:
   ```bash
   # For stateless applications
   helm install my-app pfnapp/deploy -f examples/web-app-simple.yaml
   
   # For stateful applications  
   helm install my-db pfnapp/sts -f examples/postgresql-sts.yaml
   ```

4. **Customize** the values file for your specific requirements

## Feature Comparison Quick Reference

| Feature | pfnapp/deploy | pfnapp/sts | Use For |
|---------|---------------|-------------|---------|
| Workload Type | Deployment | StatefulSet | Stateless vs Stateful |
| Autoscaling | ✅ HPA Support | ❌ Manual scaling | Web apps vs Databases |
| Storage | Shared volumes | Unique per pod | Shared vs Persistent data |
| Pod Identity | Random names | Stable names | Ephemeral vs Stable identity |
| Service Account | Disabled default | Enabled default | Simple vs Identity-aware apps |

## Common Patterns

### Web Application Stack
```bash
# Frontend (stateless)
helm install frontend pfnapp/deploy -f examples/web-app-simple.yaml

# Backend API (stateless)  
helm install api pfnapp/deploy -f examples/api-gateway.yaml

# Database (stateful)
helm install db pfnapp/sts -f examples/postgresql-sts.yaml
```

### Microservices Architecture
```bash
# User service
helm install user-service pfnapp/deploy -f examples/microservice-db.yaml

# Order service  
helm install order-service pfnapp/deploy -f examples/microservice-db.yaml

# Message queue
helm install queue pfnapp/sts -f examples/message-queue-sts.yaml
```

### Data Pipeline
```bash
# Processing service (stateless)
helm install processor pfnapp/deploy -f examples/multi-container-app.yaml

# Storage service (stateful)
helm install storage pfnapp/sts -f examples/elasticsearch-sts.yaml
```

## Best Practices

1. **Resource Limits**: Always set resource requests and limits
2. **Health Checks**: Configure appropriate probes for your application
3. **Security**: Use service accounts and security contexts in production
4. **Storage**: Choose the right storage access mode for your use case
5. **Ingress**: Use appropriate ingress strategy based on your routing needs
6. **Environment**: Separate configurations for different environments
7. **Monitoring**: Enable logging and monitoring for production deployments

## Support

For questions about these examples or the charts:
1. Check the main [repository documentation](../README.md)
2. Review the chart templates and values files
3. Open an issue in the GitHub repository