#!/bin/bash
set -euo pipefail

TEST_INPUT="${1:?test selector}"

cd "$(dirname "$0")"

. ./lib/selector.sh
resolve_test_selector "$TEST_INPUT"

export OPS_BRANCH=main
export OPS_TRACE="${OPS_TRACE:-1}"
export K3S_SERVER_TRACE="${K3S_SERVER_TRACE:-1}"
echo "*** using $OPS_BRANCH ***"
echo "*** requested tag: $TEST_TAG ***"
echo "*** resolved test: $TEST_NAME -> $TEST_SELECTOR ***"
echo "*** platform: $TEST_PLATFORM | arch: $TEST_ARCH ***"
echo "*** ops trace: $OPS_TRACE | k3s server trace: $K3S_SERVER_TRACE ***"
if test -n "$TEST_HASH"
then
    echo "*** commit hash: $TEST_HASH ***"
fi

touch ../.secrets

run_step() {
    local label="${1:?step label}"
    shift
    local status=0

    echo "::group::$label"
    printf '\n[%s] START %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$label"

    set +e
    if test "${OPS_TRACE:-0}" = "1" && test -f "$1"
    then
        bash -x "$@"
    else
        "$@"
    fi
    status=$?
    set -e

    if test "$status" -eq 0
    then
        printf '[%s] PASS  %s\n\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$label"
    else
        printf '[%s] FAIL  %s (exit %s)\n\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$label" "$status"
    fi

    echo "::endgroup::"
    return "$status"
}

run_step "Deploy ($TEST_SELECTOR)" ./1-deploy.sh "$TEST_INPUT"
run_step "System Redis ($TEST_SELECTOR)" ./3-sys-redis.sh "$TEST_INPUT"
run_step "System FerretDB ($TEST_SELECTOR)" ./4a-sys-ferretdb.sh "$TEST_INPUT"
run_step "System Postgres ($TEST_SELECTOR)" ./4b-sys-postgres.sh "$TEST_INPUT"
run_step "System Minio ($TEST_SELECTOR)" ./5-sys-minio.sh "$TEST_INPUT"
run_step "Login ($TEST_SELECTOR)" ./6-login.sh "$TEST_INPUT"
run_step "Static ($TEST_SELECTOR)" ./7-static.sh "$TEST_INPUT"
run_step "User Redis ($TEST_SELECTOR)" ./8-user-redis.sh "$TEST_INPUT"
run_step "User FerretDB ($TEST_SELECTOR)" ./9a-user-ferretdb.sh "$TEST_INPUT"
run_step "User Postgres ($TEST_SELECTOR)" ./9b-user-postgres.sh "$TEST_INPUT"
run_step "User Minio ($TEST_SELECTOR)" ./10-user-minio.sh "$TEST_INPUT"
run_step "Runtime Testing ($TEST_SELECTOR)" ./14-runtime-testing.sh "$TEST_INPUT"
