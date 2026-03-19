#!/bin/bash

resolve_test_selector() {
    local raw_selector="${1:?test selector}"
    local selector="$raw_selector"

    TEST_TAG="$raw_selector"
    TEST_HASH=""
    TEST_PROFILE="default"

    if [[ "$selector" =~ ^(.+)-([0-9a-f]{7,40})$ ]]; then
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
        TEST_PROFILE="full"
        ;;
    k3s | k3s-amd | k3s-amd-slim)
        TEST_SELECTOR="k3s-amd"
        TEST_PLATFORM="k3s"
        TEST_ARCH="amd"
        TEST_PROFILE="slim"
        ;;
    k3s-amd-full)
        TEST_SELECTOR="k3s-amd"
        TEST_PLATFORM="k3s"
        TEST_ARCH="amd"
        TEST_PROFILE="full"
        ;;
    k3sarm | k3s-arm | k3s-arm-slim)
        TEST_SELECTOR="k3s-arm"
        TEST_PLATFORM="k3s"
        TEST_ARCH="arm"
        TEST_PROFILE="slim"
        ;;
    k3s-arm-full)
        TEST_SELECTOR="k3s-arm"
        TEST_PLATFORM="k3s"
        TEST_ARCH="arm"
        TEST_PROFILE="full"
        ;;
    k8s | k8s-amd)
        TEST_SELECTOR="k8s"
        TEST_PLATFORM="k8s"
        TEST_ARCH="amd"
        TEST_PROFILE="full"
        ;;
    k8sarm | k8s-arm)
        TEST_SELECTOR="k8s"
        TEST_PLATFORM="k8s"
        TEST_ARCH="arm"
        TEST_PROFILE="full"
        ;;
    mk8s | mk8s-amd)
        TEST_SELECTOR="mk8s"
        TEST_PLATFORM="mk8s"
        TEST_ARCH="amd"
        TEST_PROFILE="full"
        ;;
    mk8sarm | mk8s-arm)
        TEST_SELECTOR="mk8s"
        TEST_PLATFORM="mk8s"
        TEST_ARCH="arm"
        TEST_PROFILE="full"
        ;;
    eks | eks-amd)
        TEST_SELECTOR="eks"
        TEST_PLATFORM="eks"
        TEST_ARCH="amd"
        TEST_PROFILE="full"
        ;;
    eksarm | eks-arm)
        TEST_SELECTOR="eks"
        TEST_PLATFORM="eks"
        TEST_ARCH="arm"
        TEST_PROFILE="full"
        ;;
    aks | aks-amd)
        TEST_SELECTOR="aks"
        TEST_PLATFORM="aks"
        TEST_ARCH="amd"
        TEST_PROFILE="full"
        ;;
    aksarm | aks-arm)
        TEST_SELECTOR="aks"
        TEST_PLATFORM="aks"
        TEST_ARCH="arm"
        TEST_PROFILE="full"
        ;;
    gke | gke-amd)
        TEST_SELECTOR="gke"
        TEST_PLATFORM="gke"
        TEST_ARCH="amd"
        TEST_PROFILE="full"
        ;;
    gkearm | gke-arm)
        TEST_SELECTOR="gke"
        TEST_PLATFORM="gke"
        TEST_ARCH="arm"
        TEST_PROFILE="full"
        ;;
    osh | osh-amd)
        TEST_SELECTOR="osh"
        TEST_PLATFORM="osh"
        TEST_ARCH="amd"
        TEST_PROFILE="full"
        ;;
    osharm | osh-arm)
        TEST_SELECTOR="osh"
        TEST_PLATFORM="osh"
        TEST_ARCH="arm"
        TEST_PROFILE="full"
        ;;
    *)
        echo "ERROR: unsupported test selector '$raw_selector'" >&2
        return 1
        ;;
    esac

    export TEST_TAG TEST_NAME TEST_HASH TEST_SELECTOR TEST_PLATFORM TEST_ARCH TEST_PROFILE
}
