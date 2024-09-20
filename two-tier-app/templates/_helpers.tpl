{{- define "two-tier-app.name" -}}
{{ .Release.Name }}-{{ .Values.nameOverride | default .Chart.Name }}
{{- end }}

{{- define "two-tier-app.description" -}}
A Helm chart for deploying a two-tier application with Flask and MySQL
{{- end }}
