#!/usr/bin/env bash
set -euo pipefail

KUBECONFIG_DIR="${KUBECONFIG_DIR:-$PWD/kubeconfigs}"
mkdir -p "$KUBECONFIG_DIR"

create_user () {
  local USERNAME="$1" GROUPS="$2"
  local CERTS_DIR="${KUBECONFIG_DIR}/${USERNAME}"
  mkdir -p "$CERTS_DIR"

  # Пути к CA minikube
  local MINIKUBE_PROFILE="${MINIKUBE_PROFILE:-minikube}"
  local MINIKUBE_DIR="${HOME}/.minikube/profiles/${MINIKUBE_PROFILE}"
  local CA_KEY="${MINIKUBE_DIR}/client.key"
  local CA_CRT="${MINIKUBE_DIR}/client.crt"
  if [[ ! -f "$CA_KEY" || ! -f "$CA_CRT" ]]; then
    echo "Не найден client.{key,crt} minikube (${CA_KEY}). Убедитесь, что minikube запущен." >&2
    exit 1
  fi

  # Генерация ключа и CSR
  openssl genrsa -out "${CERTS_DIR}/${USERNAME}.key" 2048
  openssl req -new -key "${CERTS_DIR}/${USERNAME}.key" -out "${CERTS_DIR}/${USERNAME}.csr" -subj "/CN=${USERNAME}/O=${GROUPS}"
  # Подписываем пользовательский сертификат клиентским CA minikube
  openssl x509 -req -in "${CERTS_DIR}/${USERNAME}.csr" -CA "$CA_CRT" -CAkey "$CA_KEY" -CAcreateserial -out "${CERTS_DIR}/${USERNAME}.crt" -days 365

  # Формируем kubeconfig
  local KUBECONFIG_PATH="${KUBECONFIG_DIR}/${USERNAME}.kubeconfig"
  local CLUSTER_NAME="$(kubectl config view -o jsonpath='{.clusters[0].name}')"
  local CLUSTER_SERVER="$(kubectl config view -o jsonpath='{.clusters[0].cluster.server}')"
  local CLUSTER_CACERT="$(kubectl config view -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')"

  kubectl config --kubeconfig="$KUBECONFIG_PATH" set-cluster "$CLUSTER_NAME" \
    --server="$CLUSTER_SERVER" --certificate-authority="$(kubectl config view -o jsonpath='{.clusters[0].cluster.certificate-authority}')" --embed-certs=true

  kubectl config --kubeconfig="$KUBECONFIG_PATH" set-credentials "$USERNAME" \
    --client-certificate="${CERTS_DIR}/${USERNAME}.crt" --client-key="${CERTS_DIR}/${USERNAME}.key" --embed-certs=true

  kubectl config --kubeconfig="$KUBECONFIG_PATH" set-context "${USERNAME}@${CLUSTER_NAME}" \
    --cluster="$CLUSTER_NAME" --user="$USERNAME"

  echo "Создан пользователь ${USERNAME} (группы: ${GROUPS}). kubeconfig: ${KUBECONFIG_PATH}"
}

# Примерные пользователи
create_user "alice" "viewers"
create_user "bob" "devops"
create_user "charlie" "secops"
