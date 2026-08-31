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

set -eu
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/../test-ide-deployer"
ACTION="runtimeprofiletest/custom-runtime"

cd "$PROJECT_DIR"

ops ide deploy --packages

action_json=$(ops action get "$ACTION" | sed -n '/^{/,$p')
image=$(printf '%s\n' "$action_json" | jq -r '.exec.image // empty')
if test -z "$image"
then
    echo "FAIL CUSTOM RUNTIME IMAGE"
    exit 1
fi

if ops -wsk action invoke "$ACTION" -p value ready -r | grep -q '"dependency": "1.0.4"'
then
    echo "SUCCESS CUSTOM RUNTIME INVOCATION"
else
    echo "FAIL CUSTOM RUNTIME INVOCATION"
    exit 1
fi

jobs_before=$(kubectl -n nuvolaris get jobs \
    -l openserverless.apache.org/component=runtime-builder \
    --no-headers 2>/dev/null | wc -l | tr -d ' ')
ops ide deploy --packages
jobs_after=$(kubectl -n nuvolaris get jobs \
    -l openserverless.apache.org/component=runtime-builder \
    --no-headers 2>/dev/null | wc -l | tr -d ' ')

if test "$jobs_before" = "$jobs_after"
then
    echo "SUCCESS CUSTOM RUNTIME CACHE"
else
    echo "FAIL CUSTOM RUNTIME CACHE"
    exit 1
fi
