#!/bin/bash

resolve_test_selector() {
    local raw_selector="${1:?test selector}"
    local selector="$raw_selector"

    if [[ "$selector" =~ ^(.+)-([0-9]{6,})$ ]]; then
        selector="${BASH_REMATCH[1]}"
    fi

    case "$selector" in
    kind | kind-amd | kind-arm)
        TEST_SELECTOR="kind"
        TEST_PLATFORM="kind"
        TEST_ARCH="${selector#kind-}"
        ;;
    k8s | k8s-amd | k8s-arm)
        TEST_SELECTOR="k8s"
        TEST_PLATFORM="k8s"
        TEST_ARCH="${selector#k8s-}"
        ;;
    k3s-amd | k3s-arm)
        TEST_SELECTOR="$selector"
        TEST_PLATFORM="k3s"
        TEST_ARCH="${selector#k3s-}"
        ;;
    mk8s | mk8s-amd | mk8s-arm)
        TEST_SELECTOR="mk8s"
        TEST_PLATFORM="mk8s"
        TEST_ARCH="${selector#mk8s-}"
        ;;
    eks | eks-amd | eks-arm)
        TEST_SELECTOR="eks"
        TEST_PLATFORM="eks"
        TEST_ARCH="${selector#eks-}"
        ;;
    aks | aks-amd | aks-arm)
        TEST_SELECTOR="aks"
        TEST_PLATFORM="aks"
        TEST_ARCH="${selector#aks-}"
        ;;
    gke | gke-amd | gke-arm)
        TEST_SELECTOR="gke"
        TEST_PLATFORM="gke"
        TEST_ARCH="${selector#gke-}"
        ;;
    osh | osh-amd | osh-arm)
        TEST_SELECTOR="osh"
        TEST_PLATFORM="osh"
        TEST_ARCH="${selector#osh-}"
        ;;
    *)
        echo "ERROR: unsupported test selector '$raw_selector'" >&2
        return 1
        ;;
    esac

    if [[ "$TEST_ARCH" == "$selector" ]]; then
        TEST_ARCH="amd"
    fi

    export TEST_SELECTOR TEST_PLATFORM TEST_ARCH
}
