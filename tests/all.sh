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
TYPE="${1:?test type}"
TYPE="$(echo $TYPE | awk -F- '{print $1}')"

# echo
export OPS_BRANCH=main
echo "*** using $OPS_BRANCH ***"

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
./5-sys-minio.sh

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
./7-static.sh $TYPE

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
./10-user-minio.sh $TYPE

echo "##############################################"
echo "#                                            #"
echo "#            TESTING OPS RUNTIMES $TYPE      #"
echo "#                                            #"
echo "##############################################"
./14-runtime-testing.sh $TYPE
