#!/bin/bash

resolve_test_selector() {
    local raw_selector="${1:?test selector}"
    local selector="$raw_selector"

    TEST_TAG="$raw_selector"
    TEST_HASH=""

    if [[ "$selector" =~ ^([a-z0-9]+)-([0-9a-f]{7,40})$ ]]; then
        TEST_NAME="${BASH_REMATCH[1]}"
        TEST_HASH="${BASH_REMATCH[2]}"
    else
        TEST_NAME="$selector"
    fi

    case "$TEST_NAME" in
    kind | kind-amd)
        TEST_SELECTOR="kind"
        TEST_PLATFORM="kind"
        TEST_ARCH="amd"
        ;;
    k3s | k3s-amd)
        TEST_SELECTOR="k3s-amd"
        TEST_PLATFORM="k3s"
        TEST_ARCH="amd"
        ;;
    k3sarm | k3s-arm)
        TEST_SELECTOR="k3s-arm"
        TEST_PLATFORM="k3s"
        TEST_ARCH="arm"
        ;;
    k8s | k8s-amd)
        TEST_SELECTOR="k8s"
        TEST_PLATFORM="k8s"
        TEST_ARCH="amd"
        ;;
    k8sarm | k8s-arm)
        TEST_SELECTOR="k8s"
        TEST_PLATFORM="k8s"
        TEST_ARCH="arm"
        ;;
    mk8s | mk8s-amd)
        TEST_SELECTOR="mk8s"
        TEST_PLATFORM="mk8s"
        TEST_ARCH="amd"
        ;;
    mk8sarm | mk8s-arm)
        TEST_SELECTOR="mk8s"
        TEST_PLATFORM="mk8s"
        TEST_ARCH="arm"
        ;;
    eks | eks-amd)
        TEST_SELECTOR="eks"
        TEST_PLATFORM="eks"
        TEST_ARCH="amd"
        ;;
    eksarm | eks-arm)
        TEST_SELECTOR="eks"
        TEST_PLATFORM="eks"
        TEST_ARCH="arm"
        ;;
    aks | aks-amd)
        TEST_SELECTOR="aks"
        TEST_PLATFORM="aks"
        TEST_ARCH="amd"
        ;;
    aksarm | aks-arm)
        TEST_SELECTOR="aks"
        TEST_PLATFORM="aks"
        TEST_ARCH="arm"
        ;;
    gke | gke-amd)
        TEST_SELECTOR="gke"
        TEST_PLATFORM="gke"
        TEST_ARCH="amd"
        ;;
    gkearm | gke-arm)
        TEST_SELECTOR="gke"
        TEST_PLATFORM="gke"
        TEST_ARCH="arm"
        ;;
    osh | osh-amd)
        TEST_SELECTOR="osh"
        TEST_PLATFORM="osh"
        TEST_ARCH="amd"
        ;;
    osharm | osh-arm)
        TEST_SELECTOR="osh"
        TEST_PLATFORM="osh"
        TEST_ARCH="arm"
        ;;
    *)
        echo "ERROR: unsupported test selector '$raw_selector'" >&2
        return 1
        ;;
    esac

    export TEST_TAG TEST_NAME TEST_HASH TEST_SELECTOR TEST_PLATFORM TEST_ARCH
}
