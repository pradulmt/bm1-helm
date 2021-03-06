{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "mongodb.name" -}}
{{- include "common.names.name" . -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "mongodb.fullname" -}}
{{- include "common.names.fullname" . -}}
{{- end -}}

{{/*
Return the proper MongoDB image name
*/}}
{{- define "mongodb.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper image name (for the metrics image)
*/}}
{{- define "mongodb.metrics.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.metrics.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper image name (for the init container volume-permissions image)
*/}}
{{- define "mongodb.volumePermissions.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.volumePermissions.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper image name (for the init container auto-discovery image)
*/}}
{{- define "mongodb.externalAccess.autoDiscovery.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.externalAccess.autoDiscovery.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "mongodb.imagePullSecrets" -}}
{{ include "common.images.pullSecrets" (dict "images" (list .Values.image .Values.metrics.image .Values.volumePermissions.image) "global" .Values.global) }}
{{- end -}}

{{/*
Allow the release namespace to be overridden for multi-namespace deployments in combined charts.
*/}}
/*
{{- define "mongodb.namespace" -}}
    {{- if .Values.global -}}
        {{- if .Values.global.namespaceOverride }}
            {{- .Values.global.namespaceOverride -}}
        {{- else -}}
            {{- .Release.Namespace -}}
        {{- end -}}
    {{- else -}}
        {{- .Release.Namespace -}}
    {{- end }}
{{- end -}}
{{- define "mongodb.serviceMonitor.namespace" -}}
    {{- if .Values.metrics.serviceMonitor.namespace -}}
        {{- .Values.metrics.serviceMonitor.namespace -}}
    {{- else -}}
        {{- include "mongodb.namespace" . -}}
    {{- end }}
{{- end -}}
{{- define "mongodb.prometheusRule.namespace" -}}
    {{- if .Values.metrics.prometheusRule.namespace -}}
        {{- .Values.metrics.prometheusRule.namespace -}}
    {{- else -}}
        {{- include "mongodb.namespace" . -}}
    {{- end }}
{{- end -}}
*/

{{/*
Returns the proper service account name depending if an explicit service account name is set
in the values file. If the name is not set it will default to either mongodb.fullname if serviceAccount.create
is true or default otherwise.
*/}}
{{- define "mongodb.serviceAccountName" -}}
    {{- if .Values.serviceAccount.create -}}
        {{ default (include "mongodb.fullname" .) .Values.serviceAccount.name }}
    {{- else -}}
        {{ default "default" .Values.serviceAccount.name }}
    {{- end -}}
{{- end -}}

{{/*
Return the configmap with the MongoDB configuration
*/}}
{{- define "mongodb.configmapName" -}}
{{- if .Values.existingConfigmap -}}
    {{- printf "%s" (tpl .Values.existingConfigmap $) -}}
{{- else -}}
    {{- printf "%s" (include "mongodb.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return true if a configmap object should be created for MongoDB
*/}}
{{- define "mongodb.createConfigmap" -}}
{{- if and .Values.configuration (not .Values.existingConfigmap) }}
    {{- true -}}
{{- else -}}
{{- end -}}
{{- end -}}

{{/*
Return the secret with MongoDB credentials
*/}}
{{- define "mongodb.secretName" -}}
    {{- if .Values.auth.existingSecret -}}
        {{- printf "%s" .Values.auth.existingSecret -}}
    {{- else -}}
        {{- printf "%s" (include "mongodb.fullname" .) -}}
    {{- end -}}
{{- end -}}

{{/*
Return true if a secret object should be created for MongoDB
*/}}
{{- define "mongodb.createSecret" -}}
{{- if and .Values.auth.enabled (not .Values.auth.existingSecret) }}
    {{- true -}}
{{- else -}}
{{- end -}}
{{- end -}}

{{/*
Get the initialization scripts ConfigMap name.
*/}}
{{- define "mongodb.initdbScriptsCM" -}}
{{- if .Values.initdbScriptsConfigMap -}}
{{- printf "%s" .Values.initdbScriptsConfigMap -}}
{{- else -}}
{{- printf "%s-init-scripts" (include "mongodb.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return true if the Arbiter should be deployed
*/}}
{{- define "mongodb.arbiter.enabled" -}}
{{- if and (eq .Values.architecture "replicaset") .Values.arbiter.enabled }}
    {{- true -}}
{{- else -}}
{{- end -}}
{{- end -}}

{{/*
Return the configmap with the MongoDB configuration for the Arbiter
*/}}
{{- define "mongodb.arbiter.configmapName" -}}
{{- if .Values.arbiter.existingConfigmap -}}
    {{- printf "%s" (tpl .Values.arbiter.existingConfigmap $) -}}
{{- else -}}
    {{- printf "%s-arbiter" (include "mongodb.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return true if a configmap object should be created for MongoDB Arbiter
*/}}
{{- define "mongodb.arbiter.createConfigmap" -}}
{{- if and (eq .Values.architecture "replicaset") .Values.arbiter.enabled .Values.arbiter.configuration (not .Values.arbiter.existingConfigmap) }}
    {{- true -}}
{{- else -}}
{{- end -}}
{{- end -}}

{{/*
Compile all warnings into a single message, and call fail.
*/}}
{{- define "mongodb.validateValues" -}}
{{- $messages := list -}}
{{- $messages := append $messages (include "mongodb.validateValues.architecture" .) -}}
{{- $messages := append $messages (include "mongodb.validateValues.customDatabase" .) -}}
{{- $messages := append $messages (include "mongodb.validateValues.externalAccessServiceType" .) -}}
{{- $messages := append $messages (include "mongodb.validateValues.loadBalancerIPsListLength" .) -}}
{{- $messages := append $messages (include "mongodb.validateValues.nodePortListLength" .) -}}
{{- $messages := append $messages (include "mongodb.validateValues.externalAccessAutoDiscoveryRBAC" .) -}}
{{- $messages := without $messages "" -}}
{{- $message := join "\n" $messages -}}

{{- if $message -}}
{{-   printf "\nVALUES VALIDATION:\n%s" $message | fail -}}
{{- end -}}
{{- end -}}

{{/* Validate values of MongoDB - must provide a valid architecture */}}
{{- define "mongodb.validateValues.architecture" -}}
{{- if and (ne .Values.architecture "standalone") (ne .Values.architecture "replicaset") -}}
mongodb: architecture
    Invalid architecture selected. Valid values are "standalone" and
    "replicaset". Please set a valid architecture (--set mongodb.architecture="xxxx")
{{- end -}}
{{- end -}}

{{/*
Validate values of MongoDB - both auth.username and auth.database are necessary
to create a custom user and database during 1st initialization
*/}}
{{- define "mongodb.validateValues.customDatabase" -}}
{{- if or (and .Values.auth.username (not .Values.auth.database)) (and (not .Values.auth.username) .Values.auth.database) }}
mongodb: auth.username, auth.database
    Both auth.username and auth.database must be provided to create
    a custom user and database during 1st initialization.
    Please set both of them (--set auth.username="xxxx",auth.database="yyyy")
{{- end -}}
{{- end -}}


{{/*
Validate values of MongoDB - service type for external access
*/}}
{{- define "mongodb.validateValues.externalAccessServiceType" -}}
{{- if and (eq .Values.architecture "replicaset") (not (eq .Values.externalAccess.service.type "NodePort")) (not (eq .Values.externalAccess.service.type "LoadBalancer")) -}}
mongodb: externalAccess.service.type
    Available servive type for external access are NodePort or LoadBalancer.
{{- end -}}
{{- end -}}

{{/*
Validate values of MongoDB - number of replicas must be the same than LoadBalancer IPs list
*/}}
{{- define "mongodb.validateValues.loadBalancerIPsListLength" -}}
{{- $replicaCount := int .Values.replicaCount }}
{{- $loadBalancerListLength := len .Values.externalAccess.service.loadBalancerIPs }}
{{- if and (eq .Values.architecture "replicaset") .Values.externalAccess.enabled (not .Values.externalAccess.autoDiscovery.enabled ) (eq .Values.externalAccess.service.type "LoadBalancer") (not (eq $replicaCount $loadBalancerListLength )) -}}
mongodb: .Values.externalAccess.service.loadBalancerIPs
    Number of replicas and loadBalancerIPs array length must be the same.
{{- end -}}
{{- end -}}

{{/*
Validate values of MongoDB - number of replicas must be the same than NodePort list
*/}}
{{- define "mongodb.validateValues.nodePortListLength" -}}
{{- $replicaCount := int .Values.replicaCount }}
{{- $nodePortListLength := len .Values.externalAccess.service.nodePorts }}
{{- if and (eq .Values.architecture "replicaset") .Values.externalAccess.enabled (eq .Values.externalAccess.service.type "NodePort") (not (eq $replicaCount $nodePortListLength )) -}}
mongodb: .Values.externalAccess.service.nodePorts
    Number of replicas and nodePorts array length must be the same.
{{- end -}}
{{- end -}}

{{/*
Validate values of MongoDB - RBAC should be enabled when autoDiscovery is enabled
*/}}
{{- define "mongodb.validateValues.externalAccessAutoDiscoveryRBAC" -}}
{{- if and (eq .Values.architecture "replicaset") .Values.externalAccess.enabled .Values.externalAccess.autoDiscovery.enabled (not .Values.rbac.create )}}
mongodb: rbac.create
    By specifying "externalAccess.enabled=true" and "externalAccess.autoDiscovery.enabled=true"
    an initContainer will be used to autodetect the external IPs/ports by querying the
    K8s API. Please note this initContainer requires specific RBAC resources. You can create them
    by specifying "--set rbac.create=true".
{{- end -}}
{{- end -}}
