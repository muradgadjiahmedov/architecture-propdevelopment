# Task4 — Роли и полномочия в Kubernetes (PropDevelopment)

| Роль  | Права роли | Группы пользователей |
| --- | --- | --- |
| cluster-view (ClusterRole) | get, list, watch на все стандартные ресурсы (pods, services, endpoints, deployments, statefulsets, daemonsets, jobs, cronjobs, configmaps, ingresses, namespaces, nodes — только чтение) | viewers (бизнес-пользователи, аудиторы, PM) |
| platform-operator (ClusterRole) | create, get, list, watch, update, patch, delete для workload-ресурсов в неймспейсах: deployments, statefulsets, daemonsets, jobs/cronjobs, pods, services, ingresses, configmaps, horizontalpodautoscalers; **запрещено**: secrets, RBAC, nodes; разрешено exec/port-forward | devops, sre |
| privileged-secrets-viewer (ClusterRole) | get, list, watch для secrets; get для pods/exec, logs; ограничивается **RoleBinding по конкретным namespace** | secops, oncall-leads |
| ns-admin (Role) | Полные права в рамках конкретного namespace на перечисленные выше ресурсы, включая quota/limitrange; **без** управления RBAC и cluster-scoped ресурсов | team-leads соответствующего домена |
| ns-readonly (Role) | Только get, list, watch на ресурсы в конкретном namespace | аналитики BI, QA |
| cluster-namespaces-editor (ClusterRole) | create, get, list, watch, update, patch, delete для Namespace, ResourceQuota, LimitRange (управление жизненным циклом пространств имён) | platform-team |
