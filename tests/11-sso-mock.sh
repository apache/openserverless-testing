#!/bin/bash
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
set -euo pipefail

TYPE="${1:?test type}"
TYPE="$(echo "$TYPE" | awk -F- '{print $1}')"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KUBECTL="${KUBECTL:-kubectl}"
NAMESPACE="${NAMESPACE:-nuvolaris}"
MOCK_NAME="openserverless-sso-mock"
MOCK_USER="ssomockuser"
MOCK_PASSWORD="mock-user-password"
MOCK_CLIENT_ID="openserverless-sso-mock-client"
MOCK_CLIENT_SECRET="mock-client-secret"
MOCK_GROUP="openserverless-users"
MOCK_ISSUER="http://${MOCK_NAME}.${NAMESPACE}.svc.cluster.local:8080/realms/mock"

if ! ops config sso --help >/dev/null 2>&1; then
    echo "SSO command is not available in this ops build"
    exit 1
fi

if ops config sso show 2>/dev/null | grep -q '^SSO_ENABLED=true$'; then
    echo "SSO already enabled - skipping mock SSO test to avoid changing an existing setup"
    exit 0
fi

cleanup() {
    set +e
    ops config sso disable >/dev/null 2>&1
    "$KUBECTL" -n "$NAMESPACE" delete deployment "$MOCK_NAME" --ignore-not-found >/dev/null 2>&1
    "$KUBECTL" -n "$NAMESPACE" delete service "$MOCK_NAME" --ignore-not-found >/dev/null 2>&1
    "$KUBECTL" -n "$NAMESPACE" delete configmap "$MOCK_NAME" --ignore-not-found >/dev/null 2>&1
    ops admin deleteuser "$MOCK_USER" >/dev/null 2>&1
}
trap cleanup EXIT

ops admin deleteuser "$MOCK_USER" >/dev/null 2>&1 || true

ADMIN_API_IMAGE="$("$KUBECTL" -n "$NAMESPACE" get statefulset nuvolaris-system-api -o jsonpath='{.spec.template.spec.containers[0].image}')"
if [ -z "$ADMIN_API_IMAGE" ]; then
    echo "FAIL missing admin-api image"
    exit 1
fi

"$KUBECTL" -n "$NAMESPACE" create configmap "$MOCK_NAME" \
    --from-file=mock-oidc-provider.py="$SCRIPT_DIR/mock-oidc-provider.py" \
    --dry-run=client -o yaml | "$KUBECTL" apply -f -

cat <<EOF | "$KUBECTL" apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${MOCK_NAME}
  namespace: ${NAMESPACE}
  labels:
    app: ${MOCK_NAME}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${MOCK_NAME}
  template:
    metadata:
      labels:
        app: ${MOCK_NAME}
    spec:
      containers:
      - name: mock-oidc
        image: ${ADMIN_API_IMAGE}
        imagePullPolicy: IfNotPresent
        command:
        - /home/openserverless/.venv/bin/python
        - /mock/mock-oidc-provider.py
        env:
        - name: MOCK_OIDC_ISSUER
          value: "${MOCK_ISSUER}"
        - name: MOCK_OIDC_CLIENT_ID
          value: "${MOCK_CLIENT_ID}"
        - name: MOCK_OIDC_CLIENT_SECRET
          value: "${MOCK_CLIENT_SECRET}"
        - name: MOCK_OIDC_USERNAME
          value: "${MOCK_USER}"
        - name: MOCK_OIDC_PASSWORD
          value: "${MOCK_PASSWORD}"
        - name: MOCK_OIDC_GROUP
          value: "${MOCK_GROUP}"
        ports:
        - containerPort: 8080
        readinessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 2
          periodSeconds: 2
        volumeMounts:
        - name: mock-script
          mountPath: /mock
      volumes:
      - name: mock-script
        configMap:
          name: ${MOCK_NAME}
---
apiVersion: v1
kind: Service
metadata:
  name: ${MOCK_NAME}
  namespace: ${NAMESPACE}
spec:
  selector:
    app: ${MOCK_NAME}
  ports:
  - name: http
    port: 8080
    targetPort: 8080
EOF

"$KUBECTL" -n "$NAMESPACE" rollout status "deployment/${MOCK_NAME}" --timeout=120s

ops config sso keycloak --enable \
    --issuer-url "$MOCK_ISSUER" \
    --jwks-url "${MOCK_ISSUER}/protocol/openid-connect/certs" \
    --client-id "$MOCK_CLIENT_ID" \
    --client-secret "$MOCK_CLIENT_SECRET" \
    --required-group "$MOCK_GROUP" \
    --username-claim preferred_username \
    --groups-claim groups

APIURL="$(ops debug apihost | awk '/whisk API host/{print $4}')"
if [ -z "$APIURL" ]; then
    echo "FAIL missing apihost"
    exit 1
fi

if OPS_SSO_LOGIN_FLOW=password OPS_PASSWORD="$MOCK_PASSWORD" ops -login "$APIURL" "$MOCK_USER" | grep "Successfully logged in as $MOCK_USER."; then
    echo SUCCESS SSO PASSWORD LOGIN
else
    echo FAIL SSO PASSWORD LOGIN
    exit 1
fi

ops util kube waitfor FOR=condition=ready OBJ="wsku/$MOCK_USER" TIMEOUT=120

if ops setup nuvolaris hello | grep hello; then
    echo SUCCESS SSO HELLO SETUP
else
    echo FAIL SSO HELLO SETUP
    exit 1
fi

if ops -wsk action list | grep "/$MOCK_USER/hello/hello"; then
    echo SUCCESS
    exit 0
else
    echo FAIL
    exit 1
fi
