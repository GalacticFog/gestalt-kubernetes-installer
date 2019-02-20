{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "gestalt.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "gestalt.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
  Compute Gestalt URL from ui.ingress.protocol://ui.ingress.host:ui.ingress.port
*/}}
{{- define "gestalt.url" -}}
  {{- $base_url := printf "%s://%s" .Values.ui.ingress.protocol .Values.ui.ingress.host -}}
  {{- if not (or (and (eq .Values.ui.ingress.protocol "http") (eq .Values.ui.ingress.port 80.0)) (and (eq .Values.ui.ingress.protocol "https") (eq .Values.ui.ingress.port 443.0))) -}}
    {{- printf "%s:%.0f" $base_url .Values.ui.ingress.port | b64enc | quote -}}
  {{- else -}}
    {{- $base_url | b64enc | quote -}}
  {{- end -}}
{{- end -}}

{{/*
Define database connection parameters depending on postgresql.provisionInstance boolean
*/}}
{{- define "gestalt.dbHost" -}}
  {{- if .Values.postgresql.provisionInstance -}}
    {{- printf "%s-postgresql.%s.svc.cluster.local" .Release.Name .Release.Namespace | quote -}}
  {{- else -}}
    {{- .Values.db.host | quote -}}
  {{- end -}}
{{- end -}}
{{- define "gestalt.dbPort" -}}
  {{- if .Values.postgresql.provisionInstance -}}
    {{- .Values.postgresql.service.port | quote -}}
  {{- else -}}
    {{- .Values.db.port | quote -}}
  {{- end -}}
{{- end -}}
{{- define "gestalt.dbName" -}}
  {{- if .Values.postgresql.provisionInstance -}}
    {{- .Values.postgresql.defaultName | b64enc | quote -}}
  {{- else -}}
    {{- .Values.db.name | b64enc | quote -}}
  {{- end -}}
{{- end -}}
{{- define "gestalt.dbUsername" -}}
  {{- if .Values.postgresql.provisionInstance -}}
    {{- .Values.postgresql.defaultUser | b64enc | quote -}}
  {{- else -}}
    {{- .Values.db.username | b64enc | quote -}}
  {{- end -}}
{{- end -}}
{{- define "gestalt.dbPassword" -}}
  {{- if .Values.postgresql.provisionInstance -}}
    {{- .Values.secrets.generatedPassword | b64enc | quote -}}
  {{- else -}}
    {{- .Values.db.password | b64enc | quote -}}
  {{- end -}}
{{- end -}}

{{/*
Define commonly used component and host name variables.
*/}}
{{- define "gestalt.installerName" -}}
{{- printf "%s-installer" .Release.Name | quote -}}
{{- end -}}
{{- define "gestalt.metaName" -}}
{{- printf "%s-meta" .Release.Name | quote -}}
{{- end -}}
{{- define "gestalt.metaHost" -}}
{{- printf "%s-meta.%s.svc.cluster.local" .Release.Name .Release.Namespace | quote -}}
{{- end -}}
{{- define "gestalt.secretsName" -}}
{{- printf "%s-secrets" .Release.Name | quote -}}
{{- end -}}
{{- define "gestalt.securityName" -}}
{{- printf "%s-security" .Release.Name | quote -}}
{{- end -}}
{{- define "gestalt.securityHost" -}}
{{- printf "%s-security.%s.svc.cluster.local" .Release.Name .Release.Namespace | quote -}}
{{- end -}}
{{- define "gestalt.rabbitName" -}}
{{- printf "%s-rabbit" .Release.Name | quote -}}
{{- end -}}
{{- define "gestalt.rabbitHost" -}}
{{- printf "%s-rabbit.%s" .Release.Name .Release.Namespace | quote -}}
{{- end -}}
{{- define "gestalt.elasticName" -}}
{{- printf "%s-elastic" .Release.Name | quote -}}
{{- end -}}
{{- define "gestalt.elasticHost" -}}
{{- printf "%s-elastic.%s" .Release.Name .Release.Namespace | quote -}}
{{- end -}}
{{- define "gestalt.loggingName" -}}
{{- printf "%s-log" .Release.Name | quote -}}
{{- end -}}
{{- define "gestalt.loggingHost" -}}
{{- printf "%s-log.%s.svc.cluster.local" .Release.Name .Release.Namespace | quote -}}
{{- end -}}
{{- define "gestalt.uiName" -}}
{{- printf "%s-ui" .Release.Name | quote -}}
{{- end -}}
{{- define "gestalt.uiHost" -}}
{{- printf "%s-ui.%s.svc.cluster.local" .Release.Name .Release.Namespace | quote -}}
{{- end -}}
{{- define "gestalt.redisName" -}}
{{- printf "%s-redis" .Release.Name | quote -}}
{{- end -}}
{{- define "gestalt.redisHost" -}}
{{- printf "%s-redis.%s" .Release.Name .Release.Namespace | quote -}}
{{- end -}}
{{- define "gestalt.ubbName" -}}
{{- printf "%s-ubb" .Release.Name | quote -}}
{{- end -}}
{{- define "gestalt.ubbHost" -}}
{{- printf "%s-ubb.%s" .Release.Name .Release.Namespace | quote -}}
{{- end -}}
{{- define "gestalt.trackingName" -}}
{{- printf "%s-tracking-service" .Release.Name | quote -}}
{{- end -}}
