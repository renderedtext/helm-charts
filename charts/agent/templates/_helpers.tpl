{{/*
Expand the name of the chart.
*/}}
{{- define "agent.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "agent.fullname" -}}
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
{{- define "agent.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "agent.labels" -}}
helm.sh/chart: {{ include "agent.chart" . }}
{{ include "agent.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "agent.selectorLabels" -}}
app.kubernetes.io/name: {{ include "agent.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Labels for the secret used to store the agent type information.
*/}}
{{- define "agent.secret.labels" -}}
{{ include "agent.labels" . }}
{{- if .Values.agent.autoscaling.enabled }}
semaphore-agent/autoscaled: "true"
{{- end }}
{{- end }}

{{/*
Expand the name of the pod spec config map.
*/}}
{{- define "agent.podSpecName" -}}
{{ include "agent.fullname" . }}-pod-spec
{{- end }}

{{/*
Define the main container configuration.
If preJobHook is used, we need to modify it to include the hook mount.
*/}}
{{- define "agent.job.podSpec.mainContainer" -}}
{{- if .Values.jobs.preJobHook.enabled }}
{{- $mainContainerSpec := deepCopy .Values.jobs.podSpec.mainContainer }}
{{- $preJobHookMount := dict "name" "agent-config-volume" "mountPath" .Values.jobs.preJobHook.path "readOnly" true "subPath" "pre-job-hook" }}
{{- $currentVolumeMounts := $mainContainerSpec.volumeMounts | default list }}
{{- $newVolumeMounts := append $currentVolumeMounts $preJobHookMount }}
{{- $_ := set $mainContainerSpec "volumeMounts" $newVolumeMounts }}
{{- toYaml $mainContainerSpec }}
{{- else }}
{{- toYaml .Values.jobs.podSpec.mainContainer }}
{{- end }}
{{- end }}

{{/*
Define the pod configuration.
If preJobHook is used, we need to modify it to include the hook mount.
*/}}
{{- define "agent.job.podSpec.pod" -}}
{{- if .Values.jobs.preJobHook.enabled }}
{{- $podSpec := deepCopy .Values.jobs.podSpec.pod }}
{{- $secretItem := dict "key" "pre-job-hook" "path" "pre-job-hook" }}
{{- $secretDict := dict "secretName" (include "agent.fullname" .) "defaultMode" 0644 "items" (list $secretItem) }}
{{- $preJobHookVolume := dict "name" "agent-config-volume" "secret" $secretDict }}
{{- $currentVolumes := $podSpec.volumes | default list }}
{{- $newVolumes := append $currentVolumes $preJobHookVolume }}
{{- $_ := set $podSpec "volumes" $newVolumes }}
{{- toYaml $podSpec }}
{{- else }}
{{- toYaml .Values.jobs.podSpec.pod }}
{{- end }}
{{- end }}
