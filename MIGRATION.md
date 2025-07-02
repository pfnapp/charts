# Migration Guide: Single Chart to Split Charts

## Overview

The PFNApp charts have been restructured from a single combined chart to three separate charts for better maintainability and clarity:

- **`pfnapp/common`** - Library chart with shared templates
- **`pfnapp/deploy`** - For Deployment workloads 
- **`pfnapp/sts`** - For StatefulSet workloads

## Breaking Changes

### Version 2.0.0

- **Removed**: `deploymentType` parameter
- **Changed**: Chart names and structure
- **Requires**: Full migration (uninstall/reinstall)

## Migration Steps

### 1. Backup Current Configuration

```bash
# Backup your current values
helm get values my-release > my-release-values.yaml

# Backup your current configuration
kubectl get all,configmap,secret,ingress -l app.kubernetes.io/instance=my-release > my-release-backup.yaml
```

### 2. Choose Your Chart

Based on your previous `deploymentType` setting:

- If `deploymentType: "deployment"` → Use `pfnapp/deploy`
- If `deploymentType: "statefulset"` → Use `pfnapp/sts`

### 3. Update Values File

Remove the `deploymentType` parameter from your values file:

```yaml
# REMOVE THIS LINE:
# deploymentType: "deployment"

# Keep all other configurations
app:
  name: "myapp"
# ... rest of your values
```

### 4. Uninstall and Reinstall

```bash
# 1. Uninstall the old release
helm uninstall my-release

# 2. Install with the new chart
# For Deployment workloads:
helm install my-release pfnapp/deploy -f my-release-values.yaml --version 2.0.0

# For StatefulSet workloads:
helm install my-release pfnapp/sts -f my-release-values.yaml --version 2.0.0
```

## Chart-Specific Changes

### Deploy Chart (`pfnapp/deploy`)

- **Includes**: Deployment, HPA templates
- **Removes**: StatefulSet-specific configurations
- **Dependencies**: `pfnapp/common@1.0.0`

### STS Chart (`pfnapp/sts`)

- **Includes**: StatefulSet templates
- **Removes**: HPA (not compatible with StatefulSets)
- **Dependencies**: `pfnapp/common@1.0.0`

### Common Chart (`pfnapp/common`)

- **Type**: Library chart
- **Contains**: Shared templates (service, ingress, configmap, secret, etc.)
- **Usage**: Automatically included via dependencies

## Benefits of New Structure

1. **Simplified Maintenance**: No more conditional logic in templates
2. **Clear Purpose**: Each chart has a single, well-defined use case
3. **Independent Versioning**: Deploy and STS charts can evolve independently
4. **Reduced Complexity**: Smaller, focused values files

## Troubleshooting

### Template Errors

If you encounter template errors, ensure:

1. All helper references use `common.` prefix instead of `deploy.`
2. Values are compatible with the specific chart type
3. Dependencies are properly updated

### Missing Resources

If resources don't deploy correctly:

1. Verify chart dependencies: `helm dependency update pfnapp/deploy`
2. Check values compatibility with new chart structure
3. Ensure proper chart selection (deploy vs sts)

## Support

For issues or questions about migration:

1. Check the individual chart READMEs
2. Review the example values in `pfnapp/example/`
3. Open an issue in the repository

## Rollback

If you need to rollback to the old chart structure:

```bash
# The old chart is preserved as pfnapp/deploy-old
helm install my-release pfnapp/deploy-old -f my-old-values.yaml
```

Note: The old chart structure is deprecated and will be removed in future versions.