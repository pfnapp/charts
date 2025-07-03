# PFNApp Helm Charts - Detailed Use Cases

This document provides comprehensive examples and use cases for the PFNApp Helm charts, demonstrating real-world deployment scenarios with detailed explanations.

## Table of Contents

1. [Simple Web Application](#simple-web-application)
2. [PostgreSQL Database](#postgresql-database)
3. [API Gateway Service](#api-gateway-service)
4. [Redis Cluster](#redis-cluster)
5. [Multiple Ingress Configuration](#multiple-ingress-configuration)
6. [External Secrets Integration](#external-secrets-integration)
7. [Multiple Storage Scenarios](#multiple-storage-scenarios)
8. [Comparison Guide](#comparison-guide)

---

## Simple Web Application

**Chart:** `pfnapp/deploy` | **File:** `web-app-simple.yaml`

### Description
This example demonstrates how to deploy a basic, scalable web application using the `pfnapp/deploy` chart. It is configured for high availability, automatic scaling, and is exposed to the internet via a simple ingress controller.

### Target Scenario
This configuration is ideal for a standard web application, such as a static website, a content management system (CMS), or a stateless API backend. It's designed for workloads that need to handle variable traffic levels and require a simple, single-hostname entry point.

### Key Features Demonstrated

- **High Availability:** Starts with multiple replicas (`replicaCount: 3`) to ensure the application is resilient to single-pod failures
- **Autoscaling:** Implements a Horizontal Pod Autoscaler (HPA) that automatically scales the number of pods from 2 to 10 based on CPU and memory utilization
- **Simple Ingress:** Provides external access through a single hostname with TLS enabled via `cert-manager`
- **Shared Static Assets:** Utilizes a `ReadWriteMany` persistent volume to share common data across all application pods
- **Custom Configuration:** Injects a custom `nginx.conf` file using a `ConfigMap`
- **Robust Health Checks:** Configures liveness and readiness probes for traffic routing to healthy pods
- **Security Hardening:** Applies a `securityContext` to run the application as a non-root user

### Configuration Highlights

**Autoscaling for Traffic Spikes:**
```yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80
```

**Simple Ingress and TLS:**
```yaml
simpleIngress:
  enabled: true
  hosts:
    - host: mywebapp.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    enabled: true
    certManager: true
```

**Shared Storage for Assets:**
```yaml
simpleStorage:
  enabled: true
  size: 5Gi
  storageClass: "fast-ssd"
  mountPath: /usr/share/nginx/html
  accessModes:
    - ReadWriteMany  # Shared across pods
```

### When to Use This Pattern
- Standard stateless or semi-stateless web applications
- Deploying common software like WordPress, Ghost, or other CMS platforms
- Simple front-end applications built with frameworks like React, Vue, or Angular
- Any web service that requires basic scaling and a single, secure entry point

---

## PostgreSQL Database

**Chart:** `pfnapp/sts` | **File:** `postgresql-sts.yaml`

### Description
This example demonstrates deploying a production-grade PostgreSQL database using the `pfnapp/sts` chart. It showcases StatefulSet features including persistent storage, stable network identity, and database-specific configurations.

### Target Scenario
This configuration is perfect for deploying stateful database workloads that require persistent data storage, stable pod identity, and careful scaling considerations. Suitable for primary databases, data warehouses, or any application requiring ACID compliance.

### Key Features Demonstrated

- **Stable Identity:** Each pod gets a predictable name (`postgresql-0`, `postgresql-1`) for consistent database clustering
- **Unique Persistent Storage:** Each database instance gets its own persistent volume that survives pod restarts
- **Database Security:** Implements proper credential management using Kubernetes secrets
- **Custom Configuration:** Mounts PostgreSQL configuration files via ConfigMaps
- **Health Checks:** Database-specific health checks using `pg_isready` command
- **Service Account:** Enabled by default for integration with cloud provider IAM systems
- **Security Context:** Runs as the postgres user with appropriate file system permissions

### Configuration Highlights

**Unique Storage per Pod:**
```yaml
simpleStorage:
  enabled: true
  size: 50Gi
  storageClass: "fast-ssd"
  mountPath: /var/lib/postgresql/data
  accessModes:
    - ReadWriteOnce  # Unique storage per pod
```

**Database Credentials Management:**
```yaml
env:
  - name: POSTGRES_USER
    valueFrom:
      secretKeyRef:
        name: postgresql-credentials
        key: username
  - name: POSTGRES_PASSWORD
    valueFrom:
      secretKeyRef:
        name: postgresql-credentials
        key: password
```

**Database Health Checks:**
```yaml
livenessProbe:
  exec:
    command:
      - /bin/sh
      - -c
      - exec pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" -h 127.0.0.1 -p 5432
  initialDelaySeconds: 30
  periodSeconds: 10
```

**Service Account for Cloud Integration:**
```yaml
serviceAccount:
  create: true
  name: "postgresql-service-account"
  annotations:
    iam.gke.io/gcp-service-account: "postgresql-sa@project.iam.gserviceaccount.com"
```

### When to Use This Pattern
- Primary database deployments requiring data persistence
- Database clusters requiring stable network identities
- Applications needing ACID compliance and data durability
- Scenarios requiring integration with cloud provider IAM for database access
- Workloads that need careful, manual scaling rather than automatic scaling

---

## API Gateway Service

**Chart:** `pfnapp/deploy` | **File:** `api-gateway.yaml`

### Description
This configuration demonstrates a production-grade API gateway deployment with multiple ingress endpoints, external configuration management, and comprehensive monitoring capabilities.

### Target Scenario
Ideal for RESTful API services, microservice gateways, or any service that needs to handle multiple API versions, external configuration, and high traffic with proper rate limiting.

### Key Features Demonstrated

- **Multi-Ingress Routing:** Manages multiple API versions (`v1`, `v2`) through distinct ingress rules
- **External Configuration:** Leverages external Kubernetes `Secrets` and `ConfigMaps` for configuration management
- **Rate Limiting:** Applies different rate limits for each API version (100/min for v1, 200/min for v2)
- **Multiple Service Ports:** Exposes separate ports for application traffic (`8080`) and monitoring (`9090`)
- **Comprehensive Health Checks:** Includes `liveness`, `readiness`, and `startup` probes
- **External Secrets Integration:** References external secrets for database connections, API keys, and JWT secrets
- **Monitoring Ready:** Includes metrics endpoint and sidecar containers for log shipping

### Configuration Highlights

**Multi-Version API Routing:**
```yaml
ingresses:
  api-v1:
    enabled: true
    annotations:
      nginx.ingress.kubernetes.io/rewrite-target: /$2
      nginx.ingress.kubernetes.io/rate-limit: "100"
    hosts:
      - host: api.example.com
        paths:
          - path: /v1(/|$)(.*)
            pathType: Prefix
  api-v2:
    annotations:
      nginx.ingress.kubernetes.io/rate-limit: "200"
    hosts:
      - host: api.example.com
        paths:
          - path: /v2(/|$)(.*)
            pathType: Prefix
```

**External Configuration Management:**
```yaml
env:
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:
        name: api-database-credentials
        key: connection-string
  - name: FEATURE_FLAGS
    valueFrom:
      configMapKeyRef:
        name: api-feature-flags
        key: flags.json
```

**Multiple Service Ports:**
```yaml
service:
  type: ClusterIP
  ports:
    - name: http
      port: 8080
      targetPort: 8080
    - name: metrics
      port: 9090
      targetPort: 9090
```

### When to Use This Pattern
- RESTful API services with multiple versions
- Microservice gateways requiring external configuration
- High-traffic services needing rate limiting and load balancing
- Applications requiring comprehensive monitoring and logging
- Services that need integration with external secret management systems

---

## Redis Cluster

**Chart:** `pfnapp/sts` | **File:** `redis-cluster-sts.yaml`

### Description
This example demonstrates deploying a Redis cluster using StatefulSets, showcasing cluster initialization, unique storage per instance, and proper networking for Redis clustering.

### Target Scenario
Perfect for deploying Redis in cluster mode for high availability caching, session storage, or distributed locking mechanisms that require data persistence and cluster coordination.

### Key Features Demonstrated

- **Redis Cluster Mode:** Configures Redis in cluster mode with minimum 6 instances (3 masters + 3 replicas)
- **Cluster Initialization:** Uses init containers to automatically set up the Redis cluster
- **Unique Storage:** Each Redis instance gets its own persistent volume for data persistence
- **Stable Network Identity:** Required for Redis cluster node discovery and communication
- **Headless Service:** Enables direct pod-to-pod communication for cluster operations
- **Anti-Affinity:** Ensures Redis instances are spread across different nodes
- **Monitoring Integration:** Includes Redis exporter sidecar for Prometheus metrics

### Configuration Highlights

**Redis Cluster Configuration:**
```yaml
replicaCount: 6  # Minimum for Redis cluster
env:
  - name: REDIS_CLUSTER_ENABLED
    value: "yes"
  - name: REDIS_CLUSTER_REQUIRE_FULL_COVERAGE
    value: "no"
```

**Cluster Initialization:**
```yaml
initContainers:
  - name: cluster-init
    image: redis:7-alpine
    command:
      - /bin/sh
      - /scripts/init-cluster.sh
    env:
      - name: REDIS_CLUSTER_SIZE
        value: "6"
```

**Pod Anti-Affinity:**
```yaml
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
            - key: app.kubernetes.io/name
              operator: In
              values:
                - redis-cluster
        topologyKey: kubernetes.io/hostname
```

### When to Use This Pattern
- High-availability caching layers requiring data persistence
- Distributed session storage across multiple application instances
- Applications requiring distributed locking or pub/sub messaging
- Scenarios where Redis single-instance limitations need to be overcome
- Workloads requiring automatic failover and cluster management

---

## Multiple Ingress Configuration

**Chart:** `pfnapp/deploy` | **File:** `ingress-multiple.yaml`

### Description
This example demonstrates advanced ingress configurations with multiple endpoints, different access policies, and varied security requirements for a single application.

### Target Scenario
Suitable for applications that need to expose different interfaces (public web, API endpoints, admin panels) with different security policies, SSL configurations, and access controls.

### Key Features Demonstrated

- **Multiple Named Ingresses:** Separate ingress resources for different access patterns
- **Different SSL Strategies:** Various TLS configurations and certificate management approaches
- **Access Control:** IP whitelisting and basic authentication for admin interfaces
- **Path-Based Routing:** Different URL paths routed to different service ports
- **Rate Limiting:** Configurable rate limits per ingress endpoint
- **Security Segmentation:** Public, API, and internal admin access with appropriate security controls

### Configuration Highlights

**Public Web Interface:**
```yaml
ingresses:
  public-web:
    enabled: true
    className: "nginx-public"
    annotations:
      nginx.ingress.kubernetes.io/ssl-redirect: "true"
      cert-manager.io/cluster-issuer: "letsencrypt-prod"
    hosts:
      - host: app.example.com
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                port:
                  name: web
```

**API with Rate Limiting:**
```yaml
  api-endpoints:
    annotations:
      nginx.ingress.kubernetes.io/rate-limit: "100"
      nginx.ingress.kubernetes.io/rate-limit-window: "1m"
      nginx.ingress.kubernetes.io/rewrite-target: /$2
    hosts:
      - host: api.example.com
        paths:
          - path: /v1(/|$)(.*)
            pathType: Prefix
```

**Secured Admin Interface:**
```yaml
  admin-internal:
    annotations:
      nginx.ingress.kubernetes.io/whitelist-source-range: "10.0.0.0/8,172.16.0.0/12"
      nginx.ingress.kubernetes.io/auth-type: basic
      nginx.ingress.kubernetes.io/auth-secret: admin-auth
```

### When to Use This Pattern
- Applications with multiple user interfaces (web, API, admin)
- Services requiring different security policies per endpoint
- Multi-tenant applications with varying access requirements
- Applications needing both public and internal-only endpoints
- Complex routing scenarios with different SSL and authentication needs

---

## External Secrets Integration

**Chart:** `pfnapp/deploy` | **File:** `config-external-secrets.yaml`

### Description
This example demonstrates comprehensive integration with external secret management systems, showing how to reference secrets managed by External Secrets Operator, cloud provider secret managers, and external configuration systems.

### Target Scenario
Ideal for production applications that need to integrate with enterprise secret management, cloud provider secret services (AWS Secrets Manager, Azure Key Vault, GCP Secret Manager), and external configuration management systems.

### Key Features Demonstrated

- **External Secret References:** Configuration points to secrets managed by External Secrets Operator
- **Multiple Secret Sources:** Database credentials, API keys, cloud provider credentials from different sources
- **File-Based Secrets:** Mounting secrets as files for applications that read configuration files
- **Service Account Integration:** IRSA/Workload Identity integration for cloud provider access
- **Mixed Configuration:** Combination of external secrets and local configuration for optimal security
- **Volume-Mounted Secrets:** TLS certificates, SSH keys, and configuration files mounted as volumes

### Configuration Highlights

**External Secret References:**
```yaml
env:
  - name: DATABASE_PASSWORD
    valueFrom:
      secretKeyRef:
        name: database-credentials  # Created by External Secrets Operator
        key: password
  - name: STRIPE_API_KEY
    valueFrom:
      secretKeyRef:
        name: payment-secrets  # Created by External Secrets Operator
        key: stripe-api-key
```

**Cloud Provider Integration:**
```yaml
serviceAccount:
  create: true
  annotations:
    # AWS IRSA annotation
    eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/secure-app-role"
    # GCP Workload Identity annotation
    iam.gke.io/gcp-service-account: "secure-app@project.iam.gserviceaccount.com"
```

**Volume-Mounted Secrets:**
```yaml
volumeSecrets:
  enabled: true
  items:
    - name: tls-certs
      mountPath: /app/certs
      existingSecret: app-tls-certificates  # Created by External Secrets Operator
      defaultMode: 0400
      readOnly: true
```

### When to Use This Pattern
- Production applications requiring enterprise-grade secret management
- Applications integrating with cloud provider secret services
- Multi-environment deployments with externalized configuration
- Applications needing certificate management and rotation
- Services requiring integration with HashiCorp Vault, AWS Secrets Manager, etc.

---

## Multiple Storage Scenarios

**Chart:** `pfnapp/deploy` | **File:** `storage-multiple.yaml`

### Description
This example demonstrates complex storage requirements with multiple volume types, different storage classes, and various access patterns for data processing applications.

### Target Scenario
Perfect for data processing applications, ETL pipelines, or any workload that requires different types of storage for different purposes (fast cache, persistent data, backup storage, temporary processing).

### Key Features Demonstrated

- **Multiple Storage Types:** Fast cache (NVMe), standard data storage, backup storage, temporary volumes
- **Different Storage Classes:** Demonstrates using different storage classes for different performance needs
- **Mixed Access Modes:** ReadWriteMany for shared data, ReadWriteOnce for unique data
- **Init Container Setup:** Storage initialization and permission setup
- **Storage Lifecycle Management:** Different retention and backup policies per storage type
- **Performance Optimization:** Appropriate storage types for different workload characteristics

### Configuration Highlights

**Multiple Storage Configurations:**
```yaml
simpleStorage:
  enabled: true
  size: 50Gi
  storageClass: "fast-ssd"
  mountPath: /app/data
  accessModes:
    - ReadWriteMany  # Shared data storage

volumes:
  - name: cache-storage
    persistentVolumeClaim:
      claimName: data-processor-cache  # Fast NVMe storage
  - name: backup-storage
    persistentVolumeClaim:
      claimName: data-processor-backup  # Slower, cheaper storage
  - name: temp-processing
    emptyDir:
      sizeLimit: 10Gi  # Temporary processing space
```

**Storage Initialization:**
```yaml
initContainers:
  - name: storage-init
    image: busybox:1.35
    command:
      - /bin/sh
      - -c
      - |
        mkdir -p /app/data/{input,output,processed}
        mkdir -p /app/logs/{app,access,error}
        chmod 755 /app/data /app/cache /app/logs
```

**Different Storage Classes:**
```yaml
additionalPVCs:
  cache:
    storageClass: "nvme-ssd"  # Ultra-fast storage
    size: 20Gi
  logs:
    storageClass: "standard-ssd"  # Standard performance
    size: 100Gi
  backup:
    storageClass: "standard-hdd"  # Cost-effective storage
    size: 500Gi
```

### When to Use This Pattern
- Data processing applications with varied storage performance needs
- ETL pipelines requiring different storage tiers
- Applications with distinct hot/warm/cold data access patterns
- Workloads requiring both shared and unique storage volumes
- Services needing backup and archival storage integration

---

## Comparison Guide

### When to Use pfnapp/deploy vs pfnapp/sts

| Scenario | Recommended Chart | Key Considerations |
|----------|-------------------|-------------------|
| **Web Applications** | `pfnapp/deploy` | Stateless, can be scaled automatically, pods are interchangeable |
| **APIs & Microservices** | `pfnapp/deploy` | Benefit from HPA, external config management, load balancing |
| **Databases** | `pfnapp/sts` | Need persistent storage, stable identity, careful scaling |
| **Message Queues** | `pfnapp/sts` | Require persistent data, cluster coordination, stable networking |
| **Caches (Redis/Memcached)** | `pfnapp/sts` | Cluster mode requires stable identity, data persistence optional |
| **Content Management** | `pfnapp/deploy` | Usually stateless with external database, shared file storage |
| **Data Processing** | `pfnapp/deploy` | Can use shared storage, benefit from autoscaling during load spikes |
| **Search Engines (Elasticsearch)** | `pfnapp/sts` | Need persistent data, stable identity for cluster formation |

### Feature Comparison Quick Reference

| Feature | pfnapp/deploy | pfnapp/sts | Notes |
|---------|---------------|-------------|-------|
| **Horizontal Pod Autoscaler** | ✅ | ❌ | HPA intentionally omitted from STS for safety |
| **Shared Storage** | ✅ (ReadWriteMany) | ❌ | Deploy supports shared volumes |
| **Unique Storage per Pod** | ❌ | ✅ (ReadWriteOnce) | STS creates PVC per pod |
| **Stable Pod Identity** | ❌ | ✅ | STS provides predictable pod names |
| **Service Account** | Disabled default | Enabled default | STS apps often need identity |
| **Ingress Support** | ✅ Full support | ✅ Full support | Identical ingress capabilities |
| **External Config** | ✅ Full support | ✅ Full support | Identical configuration options |
| **Health Checks** | ✅ Full support | ✅ Full support | Identical probe configurations |

### Best Practices Summary

1. **Choose the Right Chart:**
   - Use `pfnapp/deploy` for stateless applications that can scale horizontally
   - Use `pfnapp/sts` for stateful applications requiring data persistence and stable identity

2. **Storage Strategy:**
   - Deploy chart: Use shared storage for common assets, external storage for databases
   - STS chart: Each pod gets unique storage, perfect for database instances

3. **Scaling Approach:**
   - Deploy chart: Leverage HPA for automatic scaling based on metrics
   - STS chart: Scale manually or use application-aware operators

4. **Security Considerations:**
   - Both charts support identical security features
   - Use external secret management for production deployments
   - Enable service accounts when integrating with cloud providers

5. **Monitoring & Observability:**
   - Both charts support comprehensive health checks and logging
   - Use sidecar containers for monitoring agents
   - Configure appropriate resource limits and requests