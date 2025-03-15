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

if ops config status | grep OPERATOR_COMPONENT_REDIS=true; then
    echo "REDIS ENABLED"
else
    echo "REDIS DISABLED - SKIPPING"
    exit 0
fi

user="demoredisuser"
password=$(ops -random --str 12)

if ops admin adduser $user $user@email.com $password --redis | grep "whiskuser.nuvolaris.org/$user created"; then
    echo SUCCESS CREATING $user
else
    echo FAIL CREATING $user
    exit 1
fi

ops util kube waitfor FOR=condition=ready OBJ="wsku/$user" TIMEOUT=120

case "$TYPE" in
kind)
    if OPS_USER=$user OPS_PASSWORD=$password ops -login http://localhost:3233 | grep "Successfully logged in as $user."; then
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

if ops setup nuvolaris redis | grep hello; then
    echo SUCCESS SETUP REDIS ACTION
else
    echo FAIL SETUP REDIS ACTION
    exit 1
fi

if ops -wsk action list | grep "/$user/hello/redis"; then
    echo SUCCESS USER REDIS ACTION LIST
else
    echo FAIL USER REDIS ACTION LIST
    exit 1
fi

REDIS_URL=$(ops -config REDIS_URL)
REDIS_PREFIX=$(ops -config REDIS_PREFIX)

if [ -z "$REDIS_URL" ]; then
    echo FAIL REDIS_URL
    exit 1
else
    echo SUCCESS REDIS_URL
fi

if [ -z "$REDIS_PREFIX" ]; then
    echo FAIL REDIS_PREFIX
    exit 1
else
    echo SUCCESS REDIS_PREFIX
fi

if ops -wsk action invoke hello/redis -p redis_url "$REDIS_URL" -p redis_prefix "$REDIS_PREFIX" -r | grep hello; then
    echo SUCCESS
    exit 0
else
    echo FAIL
    exit 1
fi
