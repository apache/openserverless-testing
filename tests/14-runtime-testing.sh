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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTING_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

user="testactionuser"
password=$(ops -random --str 12)

OBJECT_STORAGE_FLAG=""
if ops config status | grep -q OPERATOR_COMPONENT_SEAWEEDFS=true; then
    OBJECT_STORAGE_FLAG="--seaweedfs"
elif ops config status | grep -q OPERATOR_COMPONENT_MINIO=true; then
    OBJECT_STORAGE_FLAG="--minio"
fi

ops admin deleteuser $user 2>/dev/null || true
if ops admin adduser $user $user@email.com $password $OBJECT_STORAGE_FLAG --redis --mongodb --postgres | grep "whiskuser.nuvolaris.org/$user created"
then echo SUCCESS CREATING $user
else echo FAIL CREATING $user; exit 1
fi

ops util kube waitfor FOR=condition=ready OBJ="wsku/$user" TIMEOUT=600


APIURL=$(ops debug apihost | awk '/whisk API host/{print $4}')
if OPS_USER=$user OPS_PASSWORD=$password ops -login $APIURL | grep "Successfully logged in as $user."
then echo SUCCESS LOGIN
else echo FAIL LOGIN ; exit 1
fi

export S3_ACCESS_KEY=$(ops -config S3_ACCESS_KEY)
export S3_SECRET_KEY=$(ops -config S3_SECRET_KEY)
export S3_HOST=$(ops -config S3_HOST)
export S3_PORT=$(ops -config S3_PORT)
export S3_BUCKET_DATA=$(ops -config S3_BUCKET_DATA)
export S3_BUCKET_STATIC=$(ops -config S3_BUCKET_STATIC)
export REDIS_URL=$(ops -config REDIS_URL)
export REDIS_PREFIX=$(ops -config REDIS_PREFIX)
export MONGODB_URL=$(ops -config MONGODB_URL)
export MONGODB_DB=$user
export POSTGRES_URL=$(ops -config POSTGRES_URL)


test_invoke() {
    ACT="$1"
    RES="$2"
    for i in 1 2 3 4 5
    do
        echo "Attempt #$i"
        if ops -wsk action invoke $ACT -r | grep "$RES"
        then return 0
        fi
    done
    echo FAILED AFTER 5 attempts
    exit 1
}

if ops -wsk project deploy --manifest ${TESTING_DIR}/test-runtimes/manifest.yaml | grep Success
then echo SUCCESS DEPLOY PROJECT;
else echo FAIL DEPLOY PROJECT; exit 1
fi

#if ops -wsk action invoke javascript/hello -r| grep world
if test_invoke javascript/hello world
then echo SUCCESS JS HELLO;
else echo FAIL JS HELLO; exit 1
fi

#if ops -wsk action invoke javascript/redis -r| grep hello
if test_invoke javascript/redis hello
then echo SUCCESS JS REDIS;
else echo FAIL JS REDIS; exit 1
fi

#if ops -wsk action invoke javascript/mongodb -r| grep hello
if test_invoke javascript/mongodb hello
then echo SUCCESS JS FERRETDB;
else echo FAIL JS FERRETDB; exit 1
fi

#if ops -wsk action invoke javascript/postgres -r| grep 'Postgres is up and running!'
if test_invoke javascript/postgres 'Postgres is up and running!'
then echo SUCCESS JS POSTGRES;
else echo FAIL JS POSTGRES; exit 1
fi

#if ops -wsk action invoke javascript/minio -r| grep "$user-data"
if test_invoke javascript/minio "$user-data"
then echo SUCCESS JS S3;
else echo FAIL JS S3; exit 1
fi

#if ops -wsk action invoke python/hello -r| grep world
if test_invoke python/hello world
then echo SUCCESS PYTHON HELLO;
else echo FAIL PYTHON HELLO; exit 1
fi

#if ops -wsk action invoke python/redis -r| grep world
if test_invoke python/redis world
then echo SUCCESS PYTHON REDIS;
else echo FAIL PYTHON REDIS; exit 1
fi

#if ops -wsk action invoke python/mongodb -r| grep world
if test_invoke python/mongodb world
then echo SUCCESS PYTHON FERRETDB;
else echo FAIL PYTHON FERRETDB; exit 1
fi

#if ops -wsk action invoke python/postgres -r| grep 'Postgres is up and running!'
if test_invoke python/postgres 'Postgres is up and running!'
then echo SUCCESS PYTHON POSTGRES;
else echo FAIL PYTHON POSTGRES; exit 1
fi

#if ops -wsk action invoke python/minio -r| grep "$user-data"
if test_invoke python/minio "$user-data"
then echo SUCCESS PYTHON MINIO; exit 0
else echo FAIL PYTHON MINIO; exit 1
fi
