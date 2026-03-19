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
. "$(dirname "$0")/lib/selector.sh"
resolve_test_selector "${1:?test selector}"
TYPE="$TEST_SELECTOR"

cd "$(dirname $0)"

if test -e ../.secrets
then source ../.secrets
else echo "missing .secrets - you should generate it"
     echo "to generate it, set .env variables from .env.dist then execute task secrets"
     echo "otherwise, just touch .secrets but be aware it will try to rebuild all the clusters (good luck)"
fi

# recode the id_rsa if setup
mkdir -p ~/.ssh
if test -n "$ID_RSA_B64"
then echo $ID_RSA_B64 | base64 -d >~/.ssh/id_rsa
     chmod 0600 ~/.ssh/id_rsa
fi

# disable preflight memory and cpu check
export PREFL_NO_CPU_CHECK=true
export PREFL_NO_MEM_CHECK=true

run_logged() {
    printf '+ '
    printf '%q ' "$@"
    printf '\n'
    "$@"
}

append_remote_trace() {
    local host="${1:-}"
    shift || true
    local message="$*"
    local remote_user="${SSH_USER:-root}"
    local remote_log="${K3S_SERVER_TRACE_LOG:-/var/log/openserverless-testing/ops-trace.log}"
    local remote_dir
    local timestamp
    local escaped

    if test "${K3S_SERVER_TRACE:-0}" != "1" || test -z "$host"
    then
        return 0
    fi

    remote_dir="$(dirname "$remote_log")"
    timestamp="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    escaped="$(printf "%s" "$message" | sed "s/'/'\\\\''/g")"

    ssh -oBatchMode=yes -oStrictHostKeyChecking=no "${remote_user}@${host}" \
        "sudo mkdir -p '$remote_dir' && printf '%s %s\n' '$timestamp' '$escaped' | sudo tee -a '$remote_log' >/dev/null" \
        || echo "WARNING: unable to append remote trace on $host" >&2
}

# actual setup
case "$TYPE" in
kind)
    # create vm with docker
    run_logged ops config reset
    run_logged ops setup devcluster --uninstall
    run_logged ops setup devcluster
    ;;
k3s-amd)
    # single AMD VM with k3s installed via ops setup server
    ops config reset
    K3S_AMD_APIHOST="${K3S_AMD_APIHOST:-${APIHOST:-api.k3s-amd.opstest.top}}"
    if test -n "$K3S_AMD_SSH_HOST"
    then
        :
    elif test "$K3S_AMD_APIHOST" = "testing.nuvolaris.dev"
    then
        K3S_AMD_SSH_HOST="testing1-k3s-amd.nuvolaris.dev"
    else
        K3S_AMD_SSH_HOST="$K3S_AMD_APIHOST"
    fi
    if test -z "$K3S_AMD_APIHOST"
    then
        echo "ERROR: K3S_AMD_APIHOST is required"
        exit 1
    fi
    export K3S_SSH_HOST="$K3S_AMD_SSH_HOST"
    export K3S_AUTOSSH="${K3S_AUTOSSH:-0}"
    if test "$K3S_AMD_SSH_HOST" != "$K3S_AMD_APIHOST"
    then
        export K3S_AUTOSSH=1
    fi
    export K3S_AUTOSSH_LOCAL_PORT="${K3S_AUTOSSH_LOCAL_PORT:-16443}"
    export K3S_AUTOSSH_REMOTE_PORT="${K3S_AUTOSSH_REMOTE_PORT:-6443}"
    append_remote_trace "$K3S_AMD_SSH_HOST" "BEGIN deploy selector=$TYPE apihost=$K3S_AMD_APIHOST ssh_host=$K3S_AMD_SSH_HOST autossh=$K3S_AUTOSSH"
    append_remote_trace "$K3S_AMD_SSH_HOST" "ops config apihost $K3S_AMD_APIHOST"
    run_logged ops config apihost "$K3S_AMD_APIHOST"
    echo "Using k3s-amd API host: $K3S_AMD_APIHOST"
    echo "Using k3s-amd SSH host: $K3S_AMD_SSH_HOST"
    # install cluster via the SSH host, optionally using an autossh kube-apiserver tunnel
    append_remote_trace "$K3S_AMD_SSH_HOST" "ops cloud k3s delete $K3S_AMD_SSH_HOST ${SSH_USER:-root}"
    run_logged ops cloud k3s delete "$K3S_AMD_SSH_HOST" "${SSH_USER:-root}"
    append_remote_trace "$K3S_AMD_SSH_HOST" "ops cloud k3s create $K3S_AMD_SSH_HOST ${SSH_USER:-root}"
    run_logged ops cloud k3s create "$K3S_AMD_SSH_HOST" "${SSH_USER:-root}"
    append_remote_trace "$K3S_AMD_SSH_HOST" "ops config slim"
    run_logged ops config slim
    append_remote_trace "$K3S_AMD_SSH_HOST" "ops setup cluster"
    run_logged ops setup cluster
    append_remote_trace "$K3S_AMD_SSH_HOST" "END deploy selector=$TYPE"
    ;;
k3s-arm)
    # single ARM VM with k3s installed via ops setup server
    ops config reset
    K3S_ARM_APIHOST="${K3S_ARM_APIHOST:-${APIHOST:-api.k3s-arm.opstest.top}}"
    K3S_ARM_SSH_HOST="${K3S_ARM_SSH_HOST:-$K3S_ARM_APIHOST}"
    if test -z "$K3S_ARM_APIHOST"
    then
        echo "ERROR: K3S_ARM_APIHOST is required"
        exit 1
    fi
    export K3S_SSH_HOST="$K3S_ARM_SSH_HOST"
    export K3S_AUTOSSH="${K3S_AUTOSSH:-0}"
    if test "$K3S_ARM_SSH_HOST" != "$K3S_ARM_APIHOST"
    then
        export K3S_AUTOSSH=1
    fi
    export K3S_AUTOSSH_LOCAL_PORT="${K3S_AUTOSSH_LOCAL_PORT:-26443}"
    export K3S_AUTOSSH_REMOTE_PORT="${K3S_AUTOSSH_REMOTE_PORT:-6443}"
    append_remote_trace "$K3S_ARM_SSH_HOST" "BEGIN deploy selector=$TYPE apihost=$K3S_ARM_APIHOST ssh_host=$K3S_ARM_SSH_HOST autossh=$K3S_AUTOSSH"
    append_remote_trace "$K3S_ARM_SSH_HOST" "ops config apihost $K3S_ARM_APIHOST"
    run_logged ops config apihost "$K3S_ARM_APIHOST"
    echo "Using k3s-arm API host: $K3S_ARM_APIHOST"
    echo "Using k3s-arm SSH host: $K3S_ARM_SSH_HOST"
    # install cluster via the SSH host, optionally using an autossh kube-apiserver tunnel
    append_remote_trace "$K3S_ARM_SSH_HOST" "ops cloud k3s delete $K3S_ARM_SSH_HOST ${SSH_USER:-root}"
    run_logged ops cloud k3s delete "$K3S_ARM_SSH_HOST" "${SSH_USER:-root}"
    append_remote_trace "$K3S_ARM_SSH_HOST" "ops cloud k3s create $K3S_ARM_SSH_HOST ${SSH_USER:-root}"
    run_logged ops cloud k3s create "$K3S_ARM_SSH_HOST" "${SSH_USER:-root}"
    append_remote_trace "$K3S_ARM_SSH_HOST" "ops config slim"
    run_logged ops config slim
    append_remote_trace "$K3S_ARM_SSH_HOST" "ops setup cluster"
    run_logged ops setup cluster
    append_remote_trace "$K3S_ARM_SSH_HOST" "END deploy selector=$TYPE"
    ;;

# ---------------------------------------------------------------
# Commented out -- cloud provider platforms not currently in use.
# Uncomment and configure the corresponding secrets to re-enable.
# ---------------------------------------------------------------

# mk8s)
#     ops config reset
#     # create vm with mk8s
#     if test -n "$MK8S_IP"
#     then
#           ops config apihost api.mk8s.opstest.top
#           ops cloud mk8s kubeconfig "$MK8S_IP" ubuntu
#     else
#         task azure:vm:config
#         ops cloud azcloud vm-create mk8s-test
#         ops cloud azcloud zone-update mk8s.opstest.top --wildcard --vm=mk8s-test
#         ops cloud azcloud vm-getip mk8s-test >_ip
#         ops cloud mk8s create "$(cat _ip)" ubuntu
#         ops cloud mk8s kubeconfig "$(cat _ip)" ubuntu
#     fi
#     # install cluster
#     ops setup cluster --uninstall
#     ops setup cluster
#     ;;

# eks)
#     ops config reset
#     # create cluster
#     if test -n "$EKS_KUBECONFIG_B64"
#     then
#         mkdir -p ~/.kube
#         echo $EKS_KUBECONFIG_B64 | base64 -d >~/.kube/config
#         ops config apihost api.eks.opstest.top
#         ops config use 0
#     else
#         task aws:config
#         task eks:config
#         ops cloud eks create
#         POS=$(ops config use | grep "eks-eks-test" | sed 's/*//' | awk '{print $1}')
#         if [ "$POS" != "" ]; then
#           ops config use $POS
#         else
#           ops cloud eks kubeconfig
#         fi
#         ops cloud eks lb >_cname
#         ops cloud azcloud zone-update eks.opstest.top --wildcard --cname=$(cat _cname)
#         # on eks we need to setup an initial apihost resolving the NLB hostname
#         ops config apihost api.eks.opstest.top
#     fi
#     # install cluster
#     ops debug defin
#     ops setup cluster --uninstall
#     ops setup cluster
#     ;;

# aks)
#     ops config reset
#     # create cluster
#     if test -n "$AKS_KUBECONFIG_B64"
#     then
#         mkdir -p ~/.kube
#         echo $AKS_KUBECONFIG_B64 | base64 -d >~/.kube/config
#         ops config use 0
#         ops config apihost api.aks.opstest.top
#     else
#         task azure:cluster:config
#         ops cloud aks create
#
#         POS=$(ops config use | grep "aks-aks-test" | sed 's/*//' | awk '{print $1}')
#         if [ "$POS" != "" ]; then
#           ops config use $POS
#         else
#           ops cloud aks kubeconfig
#         fi
#
#         IP=$(ops cloud aks lb)
#         ops cloud azcloud zone-update aks.opstest.top --wildcard --ip $IP
#     fi
#     # install cluster
#     ops debug defin
#     ops setup cluster --uninstall
#     ops setup cluster
#     ;;

# gke)
#     ops config reset
#     # create cluster
#     if test -n "$GCLOUD_SERVICE_ACCOUNT_B64"
#     then
#         mkdir -p ~/.kube
#         echo "$GCLOUD_SERVICE_ACCOUNT_B64" | base64 -d  >~/.kube/gcloud.json
#         gcloud auth activate-service-account --key-file ~/.kube/gcloud.json
#         gcloud container clusters get-credentials nuvolaris-testing --project nuvolaris-testing --region=us-east1
#
#         ops config use 0
#         ops config apihost api.gke.opstest.top
#     else
#         task gcp:vm:config
#         task aws:vm:config
#         ops cloud gke create
#         POS=$(ops config use | grep "gke-gke-test" | sed 's/*//' | awk '{print $1}')
#         if [ "$POS" != "" ]; then
#           ops config use $POS
#         else
#           ops cloud gke kubeconfig
#         fi
#         ops cloud aws zone-update gke.opstest.top --wildcard --ip $(ops cloud gke lb)
#     fi
#     # install cluster
#     ops debug defin
#     ops setup cluster --uninstall
#     ops setup cluster
#     ;;

# osh)
#     ops config reset
#     # create cluster
#     if test -n "$OPENSHIFT_KUBECONFIG_B64"
#     then
#         mkdir -p ~/.kube
#         echo $OPENSHIFT_KUBECONFIG_B64 | base64 -d >~/.kube/config
#         ops config use 0
#         ops config apihost api.apps.nuvolaris-testing.oshgcp.opstest.top
#     else
#         task osh:create
#         ops cloud osh import conf/gcp/auth/kubeconfig
#     fi
#     # install cluster
#     ops debug defin
#     ops setup cluster --uninstall
#     ops setup cluster
#     ;;

k8s)
    # generic Kubernetes cluster accessed via kubeconfig
    ops config reset
    if test -n "$K8S_KUBECONFIG_B64"
    then
        mkdir -p ~/.kube
        echo $K8S_KUBECONFIG_B64 | base64 -d > ~/.kube/config
        ops config apihost "${K8S_APIHOST:-${APIHOST:-api.k8s.opstest.top}}"
        ops config use 0
    else
        echo "ERROR: K8S_KUBECONFIG_B64 is required for k8s platform"
        exit 1
    fi
    # install cluster
    ops setup cluster --uninstall
    ops setup cluster
    ;;

esac
