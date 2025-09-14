# Task5 — Сегментация трафика в Kubernetes (NetworkPolicy)

Неймспейс (пример): `prop`

## 1) Создать namespace и 4 сервиса (pods + services) с метками
```bash
kubectl create ns prop
kubectl -n prop run front-end-app --image=nginx --labels=role=front-end --expose --port=80
kubectl -n prop run back-end-api-app --image=nginx --labels=role=back-end-api --expose --port=80
kubectl -n prop run admin-front-end-app --image=nginx --labels=role=admin-front-end --expose --port=80
kubectl -n prop run admin-back-end-api-app --image=nginx --labels=role=admin-back-end-api --expose --port=80

# (Необязательно для проверки, но по условию «новый сервис, к которому нельзя подключаться»)
kubectl -n prop run isolated-app --image=nginx --labels=role=isolated --expose --port=80
```

> Все сервисы создаются как ClusterIP по умолчанию и будут доступны по DNS-имени Service внутри namespace (например, `front-end-app`).

## 2) Применить сетевые политики
```bash
kubectl -n prop apply -f non-admin-api-allow.yaml
```

Содержимое файла — ниже в `non-admin-api-allow.yaml` (включает default-deny, разрешения для пар и изоляцию `isolated-app`).

## 3) Проверка
```bash
# Разрешено: front-end ↔ back-end-api
kubectl -n prop run test-fe --rm -i -t --image=alpine --restart=Never -- sh -c "apk add --no-cache curl >/dev/null && curl -sS http://back-end-api-app"
kubectl -n prop run test-be --rm -i -t --image=alpine --restart=Never -- sh -c "apk add --no-cache curl >/dev/null && curl -sS http://front-end-app"

# Разрешено: admin-front-end ↔ admin-back-end-api
kubectl -n prop run test-afe --rm -i -t --image=alpine --restart=Never -- sh -c "apk add --no-cache curl >/dev/null && curl -sS http://admin-back-end-api-app"
kubectl -n prop run test-abe --rm -i -t --image=alpine --restart=Never -- sh -c 'apk add --no-cache curl >/dev/null && curl -sS http://admin-front-end-app'

# Запрещено: пересечение доменов (пример)
kubectl -n prop run test-deny --rm -i -t --image=alpine --restart=Never -- sh -c "apk add --no-cache curl >/dev/null && curl -m 2 -sS http://admin-back-end-api-app || echo BLOCKED"

# Запрещено: доступ к isolated-app
kubectl -n prop run test-iso --rm -i -t --image=alpine --restart=Never -- sh -c "apk add --no-cache curl >/dev/null && curl -m 2 -sS http://isolated-app || echo BLOCKED"
```
