# HAProxy Ingress Configuration Guide

This guide demonstrates how to use the enhanced HAProxy features available in both the `deploy` and `sts` charts through the `simpleIngress` configuration.

## Table of Contents

1. [Overview](#overview)
2. [Basic Configuration](#basic-configuration)
3. [Load Balancing](#load-balancing)
4. [Sticky Sessions](#sticky-sessions)
5. [Backend Configuration](#backend-configuration)
6. [Security Features](#security-features)
7. [Authentication](#authentication)
8. [IP Filtering](#ip-filtering)
9. [CORS Configuration](#cors-configuration)
10. [Health Checks](#health-checks)
11. [Compression](#compression)
12. [Complete Examples](#complete-examples)

## Overview

The `simpleIngress` configuration provides a powerful yet easy-to-use interface for configuring HAProxy ingress with advanced features including:

- ✅ Load balancing algorithms
- ✅ Sticky session management  
- ✅ Backend protocol configuration
- ✅ Rate limiting and security headers
- ✅ Basic authentication
- ✅ IP whitelist/blacklist
- ✅ CORS policy management
- ✅ Health check configuration
- ✅ Content compression
- ✅ Custom annotations support

## Basic Configuration

### Simple Setup

```yaml
simpleIngress:
  - enabled: true
    domain: "myapp.example.com"
    className: "haproxy"
    tls: true
    certManager:
      enabled: true
      issuer: "letsencrypt-prod"
```

This creates a basic ingress with:
- HTTPS redirect enabled
- TLS certificate from cert-manager
- Default path routing to your service

## Load Balancing

### Available Algorithms

Configure load balancing to distribute traffic efficiently across backend pods:

```yaml
simpleIngress:
  - enabled: true
    domain: "api.example.com"
    className: "haproxy"
    haproxy:
      loadBalancing:
        enabled: true
        algorithm: "leastconn"  # Options: roundrobin, leastconn, source, uri, random
```

**Algorithm Options:**
- `roundrobin` - Distributes requests evenly (default)
- `leastconn` - Routes to backend with fewest active connections
- `source` - Routes based on client IP (provides persistence)
- `uri` - Routes based on request URI
- `random` - Random distribution

## Sticky Sessions

### Cookie-Based Session Persistence

Ensure users stick to the same backend server:

```yaml
simpleIngress:
  - enabled: true
    domain: "webapp.example.com"
    className: "haproxy"
    haproxy:
      stickySession:
        enabled: true
        cookieName: "JSESSIONID"
        strategy: "insert"  # Options: insert, rewrite, prefix
```

**Strategy Options:**
- `insert` - HAProxy inserts a new cookie
- `rewrite` - HAProxy rewrites existing cookie
- `prefix` - HAProxy adds prefix to existing cookie

## Backend Configuration

### Protocol and Port Settings

Configure how HAProxy communicates with your backend:

```yaml
simpleIngress:
  - enabled: true
    domain: "grpc-api.example.com"
    className: "haproxy"
    haproxy:
      backend:
        protocol: "grpc"  # Options: http, https, h2, grpc
        port: "9090"      # Override default service port
```

**Protocol Options:**
- `http` - Standard HTTP (default)
- `https` - HTTPS to backend
- `h2` - HTTP/2
- `grpc` - gRPC protocol

## Security Features

### Rate Limiting

Protect your application from excessive requests:

```yaml
simpleIngress:
  - enabled: true
    domain: "api.example.com"
    className: "haproxy"
    haproxy:
      security:
        rateLimit:
          enabled: true
          rpm: 1000    # Requests per minute
          burst: 100   # Burst capacity
```

### Security Headers

Add security headers to requests and responses:

```yaml
simpleIngress:
  - enabled: true
    domain: "secure-app.example.com"
    className: "haproxy"
    haproxy:
      security:
        headers:
          enabled: true
          request:
            X-Forwarded-Proto: "https"
            X-Real-IP: "%ci"
          response:
            X-Frame-Options: "DENY"
            X-Content-Type-Options: "nosniff"
            Strict-Transport-Security: "max-age=31536000; includeSubDomains"
```

## Authentication

### Basic Authentication

Protect your application with HTTP Basic Auth:

```yaml
# First create a secret with auth data:
# kubectl create secret generic basic-auth-secret --from-file=auth=./htpasswd

simpleIngress:
  - enabled: true
    domain: "admin.example.com"
    className: "haproxy"
    haproxy:
      basicAuth:
        enabled: true
        secretName: "basic-auth-secret"
        realm: "Admin Panel"
```

**Creating htpasswd file:**
```bash
# Install htpasswd utility
sudo apt-get install apache2-utils

# Create password file
htpasswd -c htpasswd admin
# Enter password when prompted

# Create Kubernetes secret
kubectl create secret generic basic-auth-secret --from-file=auth=./htpasswd
```

## IP Filtering

### IP Whitelist

Allow access only from specific IP addresses:

```yaml
simpleIngress:
  - enabled: true
    domain: "internal-api.example.com"
    className: "haproxy"
    haproxy:
      ipFilter:
        whitelist:
          enabled: true
          ips:
            - "10.0.0.0/8"        # Private network
            - "192.168.1.100"     # Specific IP
            - "203.0.113.0/24"    # Office network
```

### IP Blacklist

Block access from specific IP addresses:

```yaml
simpleIngress:
  - enabled: true
    domain: "public-api.example.com"
    className: "haproxy"
    haproxy:
      ipFilter:
        blacklist:
          enabled: true
          ips:
            - "192.168.1.200"     # Blocked IP
            - "198.51.100.0/24"   # Blocked network
```

## CORS Configuration

### Cross-Origin Resource Sharing

Configure CORS policies for web applications:

```yaml
simpleIngress:
  - enabled: true
    domain: "api.example.com"
    className: "haproxy"
    haproxy:
      cors:
        enabled: true
        allowOrigin: "https://myapp.example.com"
        allowMethods: "GET, POST, PUT, DELETE, OPTIONS"
        allowHeaders: "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization"
        allowCredentials: true
```

### Multiple Origins

```yaml
simpleIngress:
  - enabled: true
    domain: "api.example.com"
    className: "haproxy"
    haproxy:
      cors:
        enabled: true
        allowOrigin: "https://app1.example.com,https://app2.example.com"
        allowMethods: "GET, POST, OPTIONS"
        allowCredentials: false
```

## Health Checks

### Backend Health Monitoring

Configure health checks for your backend services:

```yaml
simpleIngress:
  - enabled: true
    domain: "api.example.com"
    className: "haproxy"
    haproxy:
      healthCheck:
        enabled: true
        path: "/health"
        interval: "30s"
        timeout: "5s"
```

## Compression

### Content Compression

Enable compression to reduce bandwidth usage:

```yaml
simpleIngress:
  - enabled: true
    domain: "webapp.example.com"
    className: "haproxy"
    haproxy:
      compression:
        enabled: true
        types: "text/html text/plain text/css application/json application/javascript text/xml application/xml"
        minSize: "1024"  # Minimum size in bytes
```

## Complete Examples

### High-Performance API Gateway

```yaml
simpleIngress:
  - enabled: true
    domain: "api-gateway.example.com"
    className: "haproxy"
    tls: true
    certManager:
      enabled: true
      issuer: "letsencrypt-prod"
    externalDns:
      enabled: true
      target: "lb.example.com"
    haproxy:
      # Load balancing for high availability
      loadBalancing:
        enabled: true
        algorithm: "leastconn"
      
      # Backend configuration
      backend:
        protocol: "http"
        
      # Security features
      security:
        rateLimit:
          enabled: true
          rpm: 5000
          burst: 500
        headers:
          enabled: true
          request:
            X-Forwarded-Proto: "https"
            X-Real-IP: "%ci"
          response:
            X-Frame-Options: "SAMEORIGIN"
            X-Content-Type-Options: "nosniff"
            
      # CORS for API access
      cors:
        enabled: true
        allowOrigin: "*"
        allowMethods: "GET, POST, PUT, DELETE, OPTIONS"
        allowHeaders: "Content-Type,Authorization,X-Requested-With"
        allowCredentials: false
        
      # Health monitoring
      healthCheck:
        enabled: true
        path: "/api/health"
        interval: "30s"
        timeout: "5s"
        
      # Compression for responses
      compression:
        enabled: true
        types: "application/json application/xml text/plain"
        minSize: "512"
```

### Secure Admin Panel

```yaml
simpleIngress:
  - enabled: true
    domain: "admin.example.com"
    className: "haproxy"
    tls: true
    certManager:
      enabled: true
      issuer: "letsencrypt-prod"
    haproxy:
      # Sticky sessions for admin users
      stickySession:
        enabled: true
        cookieName: "ADMIN_SESSION"
        strategy: "insert"
        
      # Security measures
      security:
        rateLimit:
          enabled: true
          rpm: 100
          burst: 20
        headers:
          enabled: true
          response:
            X-Frame-Options: "DENY"
            X-Content-Type-Options: "nosniff"
            Strict-Transport-Security: "max-age=31536000"
            
      # Basic authentication
      basicAuth:
        enabled: true
        secretName: "admin-auth-secret"
        realm: "Admin Panel - Authorized Personnel Only"
        
      # IP whitelist for office network
      ipFilter:
        whitelist:
          enabled: true
          ips:
            - "10.0.0.0/8"
            - "203.0.113.0/24"  # Office network
```

### Database API with StatefulSet

```yaml
# For pfnapp/sts chart
simpleIngress:
  - enabled: true
    domain: "db-api.example.com"
    className: "haproxy"
    tls: true
    certManager:
      enabled: true
      issuer: "letsencrypt-prod"
    haproxy:
      # Session persistence for database connections
      stickySession:
        enabled: true
        cookieName: "DB_SESSION"
        strategy: "insert"
        
      # Load balancing optimized for persistent connections
      loadBalancing:
        enabled: true
        algorithm: "source"  # IP-based persistence
        
      # Backend configuration
      backend:
        protocol: "http"
        port: "5432"
        
      # Conservative rate limiting for database
      security:
        rateLimit:
          enabled: true
          rpm: 200
          burst: 50
          
      # Health checks for database readiness
      healthCheck:
        enabled: true
        path: "/health"
        interval: "60s"
        timeout: "10s"
```

### Microservice with Multiple Features

```yaml
simpleIngress:
  - enabled: true
    domain: "microservice.example.com"
    className: "haproxy"
    tls: true
    certManager:
      enabled: true
      issuer: "letsencrypt-prod"
    externalDns:
      enabled: true
      target: "microservice-lb.example.com"
    haproxy:
      # Round-robin load balancing
      loadBalancing:
        enabled: true
        algorithm: "roundrobin"
        
      # HTTP/2 backend
      backend:
        protocol: "h2"
        
      # Comprehensive security
      security:
        rateLimit:
          enabled: true
          rpm: 2000
          burst: 200
        headers:
          enabled: true
          request:
            X-Request-ID: "%ID"
            X-Forwarded-Proto: "https"
          response:
            X-Service-Version: "v1.2.3"
            Cache-Control: "no-cache, no-store, must-revalidate"
            
      # CORS for frontend integration
      cors:
        enabled: true
        allowOrigin: "https://frontend.example.com"
        allowMethods: "GET, POST, PUT, DELETE, OPTIONS"
        allowHeaders: "Content-Type,Authorization,X-Request-ID"
        allowCredentials: true
        
      # Health monitoring
      healthCheck:
        enabled: true
        path: "/actuator/health"
        interval: "20s"
        timeout: "3s"
        
      # Compression for API responses
      compression:
        enabled: true
        types: "application/json text/plain"
        minSize: "256"
        
    # Custom annotations for additional features
    annotations:
      haproxy.ingress.kubernetes.io/timeout-client: "30s"
      haproxy.ingress.kubernetes.io/timeout-server: "30s"
      prometheus.io/scrape: "true"
```

## Best Practices

### Performance Optimization

1. **Load Balancing**: Use `leastconn` for uneven workloads, `roundrobin` for uniform workloads
2. **Compression**: Enable for text-based content, set appropriate minimum sizes
3. **Health Checks**: Configure reasonable intervals to avoid overwhelming backends

### Security Hardening

1. **Rate Limiting**: Set conservative limits and monitor for abuse
2. **IP Filtering**: Use whitelist for sensitive applications
3. **Headers**: Always add security headers for public-facing applications
4. **Authentication**: Combine basic auth with IP filtering for maximum security

### Monitoring and Debugging

1. **Health Checks**: Always configure health checks for production
2. **Custom Headers**: Add request IDs for tracing
3. **Logging**: Use HAProxy's built-in logging capabilities

### Chart Selection

- **Deploy Chart**: Use for stateless applications (web apps, APIs, microservices)
- **STS Chart**: Use for stateful applications (databases, message queues, persistent services)

## Troubleshooting

### Common Issues

1. **502 Bad Gateway**: Check backend health and service connectivity
2. **Rate Limiting**: Monitor HAProxy logs for rate limit hits
3. **CORS Errors**: Verify allowOrigin, allowMethods, and allowHeaders settings
4. **Authentication Failures**: Ensure secret exists and contains valid htpasswd data

### Debugging Commands

```bash
# Check ingress resources
kubectl get ingress -A

# Describe ingress for annotations
kubectl describe ingress <ingress-name>

# Check HAProxy controller logs
kubectl logs -n haproxy-controller <controller-pod>

# Test connectivity
curl -H "Host: myapp.example.com" http://<ingress-ip>/
```

## Reference

### HAProxy Annotations Used

- `haproxy.ingress.kubernetes.io/balance`
- `haproxy.ingress.kubernetes.io/cookie-name`
- `haproxy.ingress.kubernetes.io/cookie-strategy`
- `haproxy.ingress.kubernetes.io/backend-protocol`
- `haproxy.ingress.kubernetes.io/server-port`
- `haproxy.ingress.kubernetes.io/rate-limit-rpm`
- `haproxy.ingress.kubernetes.io/rate-limit-burst`
- `haproxy.ingress.kubernetes.io/set-header`
- `haproxy.ingress.kubernetes.io/response-set-header`
- `haproxy.ingress.kubernetes.io/auth-type`
- `haproxy.ingress.kubernetes.io/auth-secret`
- `haproxy.ingress.kubernetes.io/auth-realm`
- `haproxy.ingress.kubernetes.io/whitelist-source-range`
- `haproxy.ingress.kubernetes.io/blacklist-source-range`
- `haproxy.ingress.kubernetes.io/enable-cors`
- `haproxy.ingress.kubernetes.io/cors-allow-origin`
- `haproxy.ingress.kubernetes.io/cors-allow-methods`
- `haproxy.ingress.kubernetes.io/cors-allow-headers`
- `haproxy.ingress.kubernetes.io/cors-allow-credentials`
- `haproxy.ingress.kubernetes.io/health-check-path`
- `haproxy.ingress.kubernetes.io/health-check-interval`
- `haproxy.ingress.kubernetes.io/health-check-timeout`
- `haproxy.ingress.kubernetes.io/enable-compression`
- `haproxy.ingress.kubernetes.io/compression-type`
- `haproxy.ingress.kubernetes.io/compression-min-size`

For more information, see the [HAProxy Kubernetes Ingress Controller Documentation](https://www.haproxy.com/documentation/kubernetes-ingress/).