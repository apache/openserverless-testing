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
PROFILE="${TEST_PROFILE:-full}"

echo "*** requested tag: $TEST_TAG ***"
echo "*** resolved test: $TEST_NAME -> $TEST_SELECTOR ***"
echo "*** platform: $TEST_PLATFORM | arch: $TEST_ARCH ***"
echo "*** profile: $TEST_PROFILE ***"
if test -n "$TEST_HASH"
then
    echo "*** commit hash: $TEST_HASH ***"
fi

# Always use the main OPS branch for the local all.sh sequence.
export OPS_BRANCH=main
echo "*** using $OPS_BRANCH ***"

# if type not in (kind, k3s, mk8s, aks, eks, gke) exit

case "$TYPE" in
"k3s-amd" | "k3s-arm" | "k8s" | "kind" | "mk8s" | "gke" | "aks" | "eks" | "osh")
	# The TYPE matches one of the allowed values, so continue with the script
	;;
*)
	# TYPE does not match any of the allowed values, so exit with an error message
	echo "Error: input must be one of 'kind', 'k3s-amd', 'k3s-arm', 'k8s', 'mk8s', 'gke', 'aks', 'eks', or 'osh'."
	exit 1
	;;
esac

echo "##############################################"
echo "#                                            #"
echo "#             DEPLOYING $TYPE                #"
echo "#                                            #"
echo "##############################################"
./1-deploy.sh $TYPE

echo "##############################################"
echo "#                                            #"
echo "#             TESTING SSL $TYPE              #"
echo "#                                            #"
echo "##############################################"
./2-ssl.sh $TYPE

echo "##############################################"
echo "#                                            #"
echo "#            TESTING REDIS $TYPE             #"
echo "#                                            #"
echo "##############################################"
./3-sys-redis.sh

echo "##############################################"
echo "#                                            #"
echo "#    TESTING FERRETDB (MONGO) $TYPE          #"
echo "#                                            #"
echo "##############################################"
./4a-sys-ferretdb.sh

echo "##############################################"
echo "#                                            #"
echo "#            TESTING POSTGRES $TYPE          #"
echo "#                                            #"
echo "##############################################"
./4b-sys-postgres.sh

echo "##############################################"
echo "#                                            #"
echo "#            TESTING MINIO $TYPE             #"
echo "#                                            #"
echo "##############################################"
if test "$PROFILE" = "full"
then
./5-sys-minio.sh
else
echo "SKIP 5-sys-minio.sh for $PROFILE profile"
fi

echo "##############################################"
echo "#                                            #"
echo "#            TESTING LOGIN $TYPE             #"
echo "#                                            #"
echo "##############################################"
./6-login.sh $TYPE

echo "##############################################"
echo "#                                            #"
echo "#            TESTING STATIC $TYPE            #"
echo "#                                            #"
echo "##############################################"
if test "$PROFILE" = "full"
then
./7-static.sh $TYPE
else
echo "SKIP 7-static.sh for $PROFILE profile"
fi

echo "##############################################"
echo "#                                            #"
echo "#            TESTING USER REDIS $TYPE        #"
echo "#                                            #"
echo "##############################################"
./8-user-redis.sh $TYPE

echo "##############################################"
echo "#                                            #"
echo "#   TESTING USER FERRETDB (MONGO) $TYPE      #"
echo "#                                            #"
echo "##############################################"
./9a-user-ferretdb.sh $TYPE

echo "##############################################"
echo "#                                            #"
echo "#            TESTING USER POSTGRES $TYPE     #"
echo "#                                            #"
echo "##############################################"
./9b-user-postgres.sh $TYPE

echo "##############################################"
echo "#                                            #"
echo "#            TESTING USER MINIO $TYPE        #"
echo "#                                            #"
echo "##############################################"
if test "$PROFILE" = "full"
then
./10-user-minio.sh $TYPE
else
echo "SKIP 10-user-minio.sh for $PROFILE profile"
fi

echo "##############################################"
echo "#                                            #"
echo "#            TESTING OPS RUNTIMES $TYPE      #"
echo "#                                            #"
echo "##############################################"
./14-runtime-testing.sh $TYPE
