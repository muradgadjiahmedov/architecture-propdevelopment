#!/usr/bin/env bash
set -euo pipefail

# Создаём пространства имён по оргструктуре
kubectl apply -f - <<'YAML'
apiVersion: v1
kind: List
items:
- apiVersion: v1
  kind: Namespace
  metadata: { name: sales }
- apiVersion: v1
  kind: Namespace
  metadata: { name: jku }
- apiVersion: v1
  kind: Namespace
  metadata: { name: finance }
- apiVersion: v1
  kind: Namespace
  metadata: { name: data }
YAML

# ClusterRole: только просмотр
kubectl apply -f - <<'YAML'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-view
rules:
- apiGroups: ["","apps","batch","autoscaling","extensions","networking.k8s.io"]
  resources: ["pods","services","endpoints","deployments","replicasets","statefulsets","daemonsets","jobs","cronjobs","configmaps","ingresses","nodes","namespaces","horizontalpodautoscalers"]
  verbs: ["get","list","watch"]
YAML

# ClusterRole: платформа — управление workload (без secrets, RBAC, nodes)
kubectl apply -f - <<'YAML'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: platform-operator
rules:
- apiGroups: ["","apps","batch","autoscaling","networking.k8s.io"]
  resources: ["pods","services","endpoints","deployments","replicasets","statefulsets","daemonsets","jobs","cronjobs","configmaps","ingresses","horizontalpodautoscalers"]
  verbs: ["get","list","watch","create","update","patch","delete"]
- apiGroups: [""]
  resources: ["pods/exec","pods/portforward","pods/log"]
  verbs: ["get","list","watch","create"]
YAML

# ClusterRole: привилегированный просмотр секретов
kubectl apply -f - <<'YAML'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: privileged-secrets-viewer
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get","list","watch"]
- apiGroups: [""]
  resources: ["pods","pods/log"]
  verbs: ["get","list","watch"]
YAML

# Role в каждом namespace: ns-admin (без RBAC и cluster-scoped)
for ns in sales jku finance data; do
kubectl -n "$ns" apply -f - <<'YAML'
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ns-admin
rules:
- apiGroups: ["","apps","batch","autoscaling","networking.k8s.io"]
  resources: ["pods","services","endpoints","deployments","replicasets","statefulsets","daemonsets","jobs","cronjobs","configmaps","ingresses","horizontalpodautoscalers","resourcequotas","limitranges"]
  verbs: ["*"]
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get","list","watch","create","update","patch","delete"]
YAML
done

# Role в каждом namespace: ns-readonly
for ns in sales jku finance data; do
kubectl -n "$ns" apply -f - <<'YAML'
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ns-readonly
rules:
- apiGroups: ["","apps","batch","autoscaling","networking.k8s.io"]
  resources: ["pods","services","endpoints","deployments","replicasets","statefulsets","daemonsets","jobs","cronjobs","configmaps","ingresses","horizontalpodautoscalers","secrets"]
  verbs: ["get","list","watch"]
YAML
done
