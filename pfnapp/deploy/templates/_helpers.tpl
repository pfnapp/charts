{{/*
Expand the name of the chart.
*/}}
{{- define "deploy.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
The name of the application for Kubernetes standard labels.
Uses app.name from values.yaml for app.kubernetes.io/name label.
This ensures proper log aggregation and resource identification.
*/}}
{{- define "deploy.appName" -}}
{{- .Values.app.name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "deploy.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "deploy.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "deploy.labels" -}}
helm.sh/chart: {{ include "deploy.chart" . }}
{{ include "deploy.selectorLabels" . }}
{{- if .Values.image.tag }}
app.kubernetes.io/version: {{ .Values.image.tag | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "deploy.selectorLabels" -}}
app.kubernetes.io/name: {{ include "deploy.appName" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "deploy.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "deploy.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Generate volume mount ConfigMap and Secret resources
*/}}
{{- define "deploy.volumeMounts.resources" -}}
{{- if and .Values.volumeConfigMaps .Values.volumeConfigMaps.enabled }}
{{- range $index, $configMap := .Values.volumeConfigMaps.items }}
{{- if not $configMap.existingConfigMap }}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "deploy.fullname" $ }}-{{ $configMap.name }}
  labels:
    {{- include "deploy.labels" $ | nindent 4 }}
data:
  {{- if $configMap.data }}
  {{- range $key, $value := $configMap.data }}
  {{ $key }}: {{ $value | quote }}
  {{- end }}
  {{- else if and $configMap.content $configMap.filename }}
  {{ $configMap.filename }}: {{ $configMap.content | quote }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- if and .Values.volumeSecrets .Values.volumeSecrets.enabled }}
{{- range $index, $secret := .Values.volumeSecrets.items }}
{{- if not $secret.existingSecret }}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ include "deploy.fullname" $ }}-{{ $secret.name }}
  labels:
    {{- include "deploy.labels" $ | nindent 4 }}
type: Opaque
{{- if $secret.data }}
data:
  {{- range $key, $value := $secret.data }}
  {{ $key }}: {{ $value }}
  {{- end }}
{{- else if and $secret.content $secret.filename }}
stringData:
  {{ $secret.filename }}: {{ $secret.content | quote }}
{{- end }}
{{- if and $secret.stringData (not (and $secret.content $secret.filename)) }}
stringData:
  {{- range $key, $value := $secret.stringData }}
  {{ $key }}: {{ $value | quote }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Generate volumes for volume mount ConfigMaps and Secrets
*/}}
{{- define "deploy.volumeMounts.volumes" -}}
{{- if and .Values.volumeConfigMaps .Values.volumeConfigMaps.enabled }}
{{- range $index, $configMap := .Values.volumeConfigMaps.items }}
- name: volume-configmap-{{ $configMap.name }}
  configMap:
    name: {{ $configMap.existingConfigMap | default (printf "%s-%s" (include "deploy.fullname" $) $configMap.name) }}
    {{- if $configMap.defaultMode }}
    defaultMode: {{ $configMap.defaultMode }}
    {{- end }}
{{- end }}
{{- end }}
{{- if and .Values.volumeSecrets .Values.volumeSecrets.enabled }}
{{- range $index, $secret := .Values.volumeSecrets.items }}
- name: volume-secret-{{ $secret.name }}
  secret:
    secretName: {{ $secret.existingSecret | default (printf "%s-%s" (include "deploy.fullname" $) $secret.name) }}
    {{- if $secret.defaultMode }}
    defaultMode: {{ $secret.defaultMode }}
    {{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Generate volumeMounts for volume mount ConfigMaps and Secrets
*/}}
{{- define "deploy.volumeMounts.mounts" -}}
{{- if and .Values.volumeConfigMaps .Values.volumeConfigMaps.enabled }}
{{- range $index, $configMap := .Values.volumeConfigMaps.items }}
- name: volume-configmap-{{ $configMap.name }}
  mountPath: {{ $configMap.mountPath }}
  {{- if $configMap.subPath }}
  subPath: {{ $configMap.subPath }}
  {{- end }}
  {{- if $configMap.readOnly }}
  readOnly: {{ $configMap.readOnly }}
  {{- end }}
{{- end }}
{{- end }}
{{- if and .Values.volumeSecrets .Values.volumeSecrets.enabled }}
{{- range $index, $secret := .Values.volumeSecrets.items }}
- name: volume-secret-{{ $secret.name }}
  mountPath: {{ $secret.mountPath }}
  {{- if $secret.subPath }}
  subPath: {{ $secret.subPath }}
  {{- end }}
  {{- if $secret.readOnly }}
  readOnly: {{ $secret.readOnly }}
  {{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Generate ingress name for simple ingress
*/}}
{{- define "deploy.ingressName" -}}
{{- printf "%s-%s" .releaseName (.domain | replace "." "-") | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Generate TLS secret name for simple ingress
*/}}
{{- define "deploy.tlsSecretName" -}}
{{- printf "%s-tls" (. | replace "." "-") | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Generate external DNS hostname annotation
*/}}
{{- define "deploy.externalDnsHostname" -}}
{{- if .externalDns.enabled }}
external-dns.alpha.kubernetes.io/hostname: {{ .domain }}
{{- if .externalDns.target }}
external-dns.alpha.kubernetes.io/target: {{ .externalDns.target }}
{{- end }}
{{- end }}
{{- end }}