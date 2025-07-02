# Common Chart

A Helm library chart containing shared templates for PFNApp charts.

## Overview

This is a **library chart** (not installable directly) that provides common templates shared between the `deploy` and `sts` charts. It contains reusable Kubernetes resource templates and helper functions.

## Purpose

- **Shared Templates**: Common Kubernetes resources (Service, Ingress, ConfigMap, Secret, etc.)
- **Helper Functions**: Reusable template functions for naming, labeling, and configuration
- **Consistency**: Ensures consistent behavior across deploy and sts charts
- **Maintainability**: Single source of truth for shared logic

## Included Templates

### Core Resources
- **Service** (`service.yaml`) - ClusterIP, NodePort, LoadBalancer services
- **ServiceAccount** (`serviceaccount.yaml`) - Pod service accounts
- **ConfigMap** (`configmap.yaml`) - Helm-managed configuration
- **Secret** (`secret.yaml`) - Helm-managed secrets

### Ingress Resources
- **Legacy Ingress** (`ingress.yaml`) - Single ingress configuration
- **Multiple Ingress** (`ingress-multiple.yaml`) - Named ingress configurations  
- **Domain-based Ingress** (`ingress-domain-based.yaml`) - Auto-generated from domains
- **Simple Ingress** (`ingress-simple.yaml`) - Simplified with cert-manager/external-dns

### Helper Templates
- **`_helpers.tpl`** - Template functions for:
  - `common.name` - Chart name generation
  - `common.fullname` - Full resource name generation
  - `common.chart` - Chart label generation
  - `common.labels` - Standard labels
  - `common.selectorLabels` - Selector labels
  - `common.serviceAccountName` - Service account name logic

## Usage

This chart is automatically included as a dependency in both `deploy` and `sts` charts:

```yaml
# Chart.yaml
dependencies:
- name: common
  version: "1.0.0"
  repository: "file://../common"
```

### Template Usage

Parent charts reference common templates using the `common.` prefix:

```yaml
# In deploy or sts chart templates
metadata:
  name: {{ include "common.fullname" . }}
  labels:
    {{- include "common.labels" . | nindent 4 }}
spec:
  selector:
    matchLabels:
      {{- include "common.selectorLabels" . | nindent 6 }}
```

## Supported Values

The common chart doesn't define its own values but operates on values passed from parent charts. See the individual chart READMEs for complete value specifications:

- [Deploy Chart Values](../deploy/README.md)
- [STS Chart Values](../sts/README.md)

## Development

### Testing

Library charts cannot be tested directly. Test through parent charts:

```bash
# Test via deploy chart
helm template test ../deploy

# Test via sts chart  
helm template test ../sts
```

### Adding New Templates

1. Create template in `templates/` directory
2. Use `common.` prefix for helper functions
3. Remove any deployment-type specific logic
4. Test through both parent charts

### Versioning

- Increment version in `Chart.yaml` when adding/changing templates
- Update parent chart dependencies accordingly
- Follow semantic versioning

## Dependencies

None - this is a base library chart.

## Chart Information

- **Type**: Library
- **Version**: 1.0.0
- **Maintainer**: pfnapp-team
- **Homepage**: https://pfnapp.github.io/charts

## Related Charts

- [Deploy Chart](../deploy/) - Uses common for Deployment workloads
- [STS Chart](../sts/) - Uses common for StatefulSet workloads