{{/*
Expand the name of the chart.
*/}}
{{- define "deploy.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
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
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "deploy.selectorLabels" -}}
app.kubernetes.io/name: {{ include "deploy.name" . }}
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
Generate TLS secret name from domain (replace dots with dashes)
Usage: {{ include "deploy.tlsSecretName" "example.com" }}
*/}}
{{- define "deploy.tlsSecretName" -}}
{{- . | replace "." "-" | trunc 63 | trimSuffix "-" }}-tls
{{- end }}

{{/*
Generate ingress name from domain (replace dots with dashes)
Usage: {{ include "deploy.ingressName" (dict "releaseName" .Release.Name "domain" "example.com") }}
*/}}
{{- define "deploy.ingressName" -}}
{{- printf "%s-%s" .releaseName (.domain | replace "." "-") | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Generate external-dns hostname annotation based on domain and externalDns config
*/}}
{{- define "deploy.externalDnsHostname" -}}
{{- if .externalDns.enabled }}
external-dns.alpha.kubernetes.io/hostname: {{ .domain }}
{{- if .externalDns.target }}
external-dns.alpha.kubernetes.io/target: {{ .externalDns.target }}
{{- end }}
{{- if hasKey .externalDns "cloudflareProxied" }}
external-dns.alpha.kubernetes.io/cloudflare-proxied: {{ .externalDns.cloudflareProxied | quote }}
{{- end }}
{{- end }}
{{- end }}