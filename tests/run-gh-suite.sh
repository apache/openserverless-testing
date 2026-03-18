#!/bin/bash
set -euo pipefail

SELECTOR="${1:?test selector}"

cd "$(dirname "$0")"

touch ../.secrets

./1-deploy.sh "$SELECTOR"
./3-sys-redis.sh "$SELECTOR"
./4a-sys-ferretdb.sh "$SELECTOR"
./4b-sys-postgres.sh "$SELECTOR"
./5-sys-minio.sh "$SELECTOR"
./6-login.sh "$SELECTOR"
./7-static.sh "$SELECTOR"
./8-user-redis.sh "$SELECTOR"
./9a-user-ferretdb.sh "$SELECTOR"
./9b-user-postgres.sh "$SELECTOR"
./10-user-minio.sh "$SELECTOR"
./14-runtime-testing.sh "$SELECTOR"
