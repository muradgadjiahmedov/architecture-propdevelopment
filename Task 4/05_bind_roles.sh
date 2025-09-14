#!/usr/bin/env bash
set -euo pipefail

# Cluster-wide: viewers -> cluster-view
kubectl create clusterrolebinding viewers-cluster-view --clusterrole=cluster-view --group=viewers --dry-run=client -o yaml | kubectl apply -f -

# Ограничение привилегированного доступа к секретам по namespace
for ns in sales jku finance data; do
  kubectl -n "$ns" create rolebinding secops-secrets-view --clusterrole=privileged-secrets-viewer --group=secops --dry-run=client -o yaml | kubectl apply -f -
done

# Разрешить devops управлять workloads во всех доменных пространствах имён
for ns in sales jku finance data; do
  kubectl -n "$ns" create rolebinding devops-operator --clusterrole=platform-operator --group=devops --dry-run=client -o yaml | kubectl apply -f -
done

# Пример точечных биндингов пользователей к namespace-ролям
kubectl -n sales create rolebinding alice-readonly --role=ns-readonly --user=alice --dry-run=client -o yaml | kubectl apply -f -
kubectl -n jku create rolebinding bob-ns-admin --role=ns-admin --user=bob --dry-run=client -o yaml | kubectl apply -f -
