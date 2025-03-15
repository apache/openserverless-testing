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

if ops config status | grep OPERATOR_COMPONENT_MINIO=true; then
    echo "MINIO ENABLED"
else
    echo "MINIO DISABLED - SKIPPING"
    exit 0
fi

user="demominiouser"
password=$(ops -random --str 12)

if ops admin adduser $user $user@email.com $password --minio | grep "whiskuser.nuvolaris.org/$user created"; then
    echo SUCCESS CREATING $user $password
else
    echo FAIL CREATING $user
    exit 1
fi

ops util kube waitfor FOR=condition=ready OBJ="wsku/$user" TIMEOUT=120

case "$TYPE" in
kind)
    if OPS_USER=$user OPS_PASSWORD=$password ops -login http://localhost:80 | grep "Successfully logged in as $user."; then
        echo SUCCESS LOGIN
    else
        echo FAIL LOGIN
        exit 1
    fi
    ;;
*)
    APIURL=$(ops debug apihost | awk '/whisk API host/{print $4}')
    if OPS_USER=$user OPS_PASSWORD=$password ops -login $APIURL | grep "Successfully logged in as $user."; then
        echo SUCCESS LOGIN
    else
        echo FAIL LOGIN
        exit 1
    fi
    ;;
esac

if ops setup nuvolaris minio | grep hello; then
    echo SUCCESS SETUP MINIO ACTION
else
    echo FAIL SETUP ACTION MINIO
    exit 1
fi

if ops -wsk action list | grep "/$user/hello/minio"; then
    echo SUCCESS USER MINIO ACTION LIST
else
    echo FAIL USER MINIO ACTION LIST
    exit 1
fi

S3_ACCESS_KEY=$(ops -config S3_ACCESS_KEY)
S3_SECRET_KEY=$(ops -config S3_SECRET_KEY)
S3_HOST=$(ops -config S3_HOST)
S3_PORT=$(ops -config S3_PORT)
S3_BUCKET_DATA=$(ops -config S3_BUCKET_DATA)
S3_BUCKET_STATIC=$(ops -config S3_BUCKET_STATIC)

if [[ -z "$S3_ACCESS_KEY" ]]; then
    echo FAIL USER S3_ACCESS_KEY
    exit 1
else
    echo SUCCESS USER S3_ACCESS_KEY
fi

if ops -wsk action invoke hello/minio -p s3_access "$S3_ACCESS_KEY" \
    -p s3_secret "$S3_SECRET_KEY" \
    -p s3_host "$S3_HOST" \
    -p s3_port "$S3_PORT" \
    -p s3_data "$S3_BUCKET_DATA" -r | grep "$user-data"; then
    echo SUCCESS
    exit 0
else
    echo FAIL ACTION INVOKE
    exit 1
fi
