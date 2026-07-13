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
set -o pipefail

TYPE="${1:?test type}"
TYPE="$(echo $TYPE | awk -F- '{print $1}')"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPEN_SERVERLESS_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

export OPS_BRANCH="${OPS_BRANCH:-main}"
if [ -d "$OPEN_SERVERLESS_ROOT/olaris" ]; then
	export OPS_ROOT="${OPS_ROOT:-$OPEN_SERVERLESS_ROOT/olaris}"
	export PATH="$OPEN_SERVERLESS_ROOT:$PATH"
fi

echo "*** using OPS_BRANCH=$OPS_BRANCH ***"
echo "*** using OPS_ROOT=${OPS_ROOT:-default} ***"

# if type not in (kind, k3s, mk8s, aks, eks, gke) exit

case "$TYPE" in
"k3s" | "mk8s" | "kind" | "gke" | "aks" | "eks" | "osh")
	# The TYPE matches one of the allowed values, so continue with the script
	;;
*)
	# TYPE does not match any of the allowed values, so exit with an error message
	echo "Error: input must be one of 'kind', 'k3s', 'mk8s', 'gke', 'aks', 'eks' or 'osh'."
	exit 1
	;;
esac

cd "$SCRIPT_DIR"
rm  -f _results _log
FAILED=0
collect() {
	if "$@" 2>&1 | tee _log
	then
		echo SUCCESS "$1" >> _results
	else
		echo FAIL "$1" >> _results
		FAILED=1
	fi
}

echo "##############################################"
echo "#                                            #"
echo "#             DEPLOYING $TYPE                #"
echo "#                                            #"
echo "##############################################"
collect ./1-deploy.sh $TYPE

echo "##############################################"
echo "#                                            #"
echo "#             TESTING SSL $TYPE              #"
echo "#                                            #"
echo "##############################################"
collect ./2-ssl.sh $TYPE

echo "##############################################"
echo "#                                            #"
echo "#            TESTING REDIS $TYPE             #"
echo "#                                            #"
echo "##############################################"
collect ./3-sys-redis.sh

echo "##############################################"
echo "#                                            #"
echo "#    TESTING FERRETDB (MONGO) $TYPE          #"
echo "#                                            #"
echo "##############################################"
collect ./4a-sys-ferretdb.sh

echo "##############################################"
echo "#                                            #"
echo "#            TESTING POSTGRES $TYPE          #"
echo "#                                            #"
echo "##############################################"
collect ./4b-sys-postgres.sh

echo "##############################################"
echo "#                                            #"
echo "#            TESTING SEAWEEDFS $TYPE             #"
echo "#                                            #"
echo "##############################################"
collect ./5-sys-seaweedfs.sh

echo "##############################################"
echo "#                                            #"
echo "#            TESTING LOGIN $TYPE             #"
echo "#                                            #"
echo "##############################################"
collect ./6-login.sh $TYPE

echo "##############################################"
echo "#                                            #"
echo "#          TESTING SSO MOCK $TYPE            #"
echo "#                                            #"
echo "##############################################"
collect ./11-sso-mock.sh $TYPE

echo "##############################################"
echo "#                                            #"
echo "#            TESTING STATIC $TYPE            #"
echo "#                                            #"
echo "##############################################"
collect ./7-static.sh $TYPE

echo "##############################################"
echo "#                                            #"
echo "#            TESTING USER REDIS $TYPE        #"
echo "#                                            #"
echo "##############################################"
collect ./8-user-redis.sh $TYPE

echo "##############################################"
echo "#                                            #"
echo "#   TESTING USER FERRETDB (MONGO) $TYPE      #"
echo "#                                            #"
echo "##############################################"
collect ./9a-user-ferretdb.sh $TYPE

echo "##############################################"
echo "#                                            #"
echo "#            TESTING USER POSTGRES $TYPE     #"
echo "#                                            #"
echo "##############################################"
collect ./9b-user-postgres.sh $TYPE

echo "##############################################"
echo "#                                            #"
echo "#          TESTING USER SEAWEEDFS $TYPE      #"
echo "#                                            #"
echo "##############################################"
collect ./10-user-seaweedfs.sh $TYPE

echo "##############################################"
echo "#                                            #"
echo "#            TESTING OPS RUNTIMES $TYPE      #"
echo "#                                            #"
echo "##############################################"
collect ./14-runtime-testing.sh $TYPE

echo "##############################################"
echo "#                                            #"
echo "#        TESTING OPS IDE DEPLOYER $TYPE      #"
echo "#                                            #"
echo "##############################################"
collect ./15-ide-deployer.sh $TYPE

echo "============================================"
cat _results
exit "$FAILED"
