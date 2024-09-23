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

if nuv config status | grep NUVOLARIS_MONGODB=true; then
    echo "MONGODB ENABLED"
else
    echo "MONGODB DISABLED - SKIPPING"
    exit 0
fi

user="demomongouser"
password=$(nuv -random --str 12)

if nuv admin adduser $user $user@email.com $password --mongodb | grep "whiskuser.nuvolaris.org/$user created"; then
    echo SUCCESS CREATING $user
else
    echo FAIL CREATING $user
    exit 1
fi

nuv util kube waitfor FOR=condition=ready OBJ="wsku/$user" TIMEOUT=120

case "$TYPE" in
kind)
    if NUV_LOGIN=$user NUV_PASSWORD=$password nuv -login http://localhost:3233 | grep "Successfully logged in as $user."; then
        echo SUCCESS LOGIN
    else
        echo FAIL LOGIN
        exit 1
    fi
    ;;
*)
    APIURL=$(nuv debug apihost | awk '/whisk API host/{print $4}')
    if NUV_LOGIN=$user NUV_PASSWORD=$password nuv -login $APIURL | grep "Successfully logged in as $user."; then
        echo SUCCESS LOGIN
    else
        echo FAIL LOGIN
        exit 1
    fi
    ;;
esac

if nuv setup nuvolaris mongodb | grep hello; then
    echo SUCCESS SETUP MONGODB ACTION
else
    echo FAIL SETUP MONGODB ACTION
    exit 1
fi

if nuv -wsk action list | grep "/$user/hello/mongodb"; then
    echo SUCCESS USER MONGODB ACTION LIST
else
    echo FAIL USER MONGODB ACTION LIST
    exit 1
fi

MONGODB_URL=$(nuv -config MONGODB_URL)

if [ -z "$MONGODB_URL" ]; then
    echo FAIL USER MONGODB_URL
    exit 1
else
    echo SUCCESS USER MONGODB_URL
fi

if nuv -wsk action invoke hello/mongodb -p mongodb_url "$MONGODB_URL" -r | grep "hello"; then
    echo SUCCESS
    exit 0
else
    echo FAIL
    exit 1
fi
