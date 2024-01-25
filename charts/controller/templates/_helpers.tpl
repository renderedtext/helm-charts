{{/*
Expand the name of the chart.
*/}}
{{- define "controller.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "controller.fullname" -}}
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
{{- define "controller.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "controller.labels" -}}
helm.sh/chart: {{ include "controller.chart" . }}
{{ include "controller.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "controller.selectorLabels" -}}
app.kubernetes.io/name: {{ include "controller.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Expand the name of the default pod spec config map.
*/}}
{{- define "controller.agent.defaultPodSpec.name" -}}
{{ include "controller.fullname" . }}-pod-spec
{{- end }}

{{/*
Define the main container configuration for the default pod spec.
*/}}
{{- define "controller.agent.defaultPodSpec.mainContainer" -}}
{{- if .Values.agent.defaultPodSpec.enabled }}
{{- $mainContainerSpec := deepCopy .Values.agent.defaultPodSpec.mainContainer }}
{{- if .Values.agent.defaultPodSpec.preJobHook.enabled }}
{{- $preJobHookMount := dict "name" "agent-config-volume" "mountPath" .Values.agent.defaultPodSpec.preJobHook.path "readOnly" true }}
{{- $currentVolumeMounts := $mainContainerSpec.volumeMounts | default list }}
{{- $newVolumeMounts := append $currentVolumeMounts $preJobHookMount }}
{{- $_ := set $mainContainerSpec "volumeMounts" $newVolumeMounts }}
{{- end }}
{{- toYaml $mainContainerSpec }}
{{- else }}
{{- toYaml dict }}
{{- end }}
{{- end }}

{{/*
Define the pod configuration for the default pod spec.
*/}}
{{- define "controller.agent.defaultPodSpec.pod" -}}
{{- if .Values.agent.defaultPodSpec.enabled }}
{{- $podSpec := deepCopy .Values.agent.defaultPodSpec.pod }}
{{- if .Values.agent.defaultPodSpec.preJobHook.enabled }}
{{- $secretItem := dict "key" "pre-job-hook" "path" "pre-job-hook" }}
{{- $secretDict := dict "secretName" (include "controller.fullname" .) "defaultMode" 0644 "items" (list $secretItem) }}
{{- $preJobHookVolume := dict "name" "agent-config-volume" "secret" $secretDict }}
{{- $currentVolumes := $podSpec.volumes | default list }}
{{- $newVolumes := append $currentVolumes $preJobHookVolume }}
{{- $_ := set $podSpec "volumes" $newVolumes }}
{{- end }}
{{- toYaml $podSpec }}
{{- else }}
{{- toYaml dict }}
{{- end }}
{{- end }}

{{/*
Expand the name of the default pod spec config map.
*/}}
{{- define "controller.agent.startupParameters" -}}
{{- $startupParameters := list }}
{{- if .Values.agent.defaultPodSpec.enabled }}
{{- $startupParameters = append $startupParameters "--kubernetes-pod-spec" }}
{{- $startupParameters = append $startupParameters (include "controller.agent.defaultPodSpec.name" .) }}
{{- end }}
{{- if .Values.agent.defaultPodSpec.preJobHook.enabled }}
{{- $startupParameters = append $startupParameters "--pre-job-hook-path" }}
{{- $startupParameters = append $startupParameters (printf "%s/pre-job-hook" .Values.agent.defaultPodSpec.preJobHook.path) }}
{{- $startupParameters = append $startupParameters "--source-pre-job-hook" }}
{{- end }}
{{- if .Values.agent.defaultPodSpec.preJobHook.failOnError }}
{{- $startupParameters = append $startupParameters "--fail-on-pre-job-hook-error" }}
{{- end }}
{{- if .Values.agent.podStartTimeout }}
{{- $startupParameters = append $startupParameters "--kubernetes-pod-start-timeout" }}
{{- $startupParameters = append $startupParameters .Values.agent.podStartTimeout }}
{{- end }}
{{- if .Values.agent.allowedImages }}
{{- $startupParameters = append $startupParameters "--kubernetes-allowed-images" }}
{{- $startupParameters = append $startupParameters .Values.agent.allowedImages }}
{{- end }}
{{- join " " $startupParameters }}
{{- end }}
