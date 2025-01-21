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

user="testactionuser"
password=$(ops -random --str 12)

if ops admin adduser $user $user@email.com $password --minio --redis --mongodb --postgres | grep "whiskuser.nuvolaris.org/$user created"
then echo SUCCESS CREATING $user
else echo FAIL CREATING $user; exit 1 
fi

ops util kube waitfor FOR=condition=ready OBJ="wsku/$user" TIMEOUT=600

case "$TYPE" in
    (kind) 
        if OPS_USER=$user OPS_PASSWORD=$password ops -login http://localhost:80 | grep "Successfully logged in as $user."
        then echo SUCCESS LOGIN
        else echo FAIL LOGIN ; exit 1 
        fi
    ;;
    *)
        APIURL=$(ops debug apihost | awk '/whisk API host/{print $4}')
        if OPS_USER=$user OPS_PASSWORD=$password ops -login $APIURL | grep "Successfully logged in as $user."
        then echo SUCCESS LOGIN
        else echo FAIL LOGIN ; exit 1 
        fi
    ;;    
esac

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

PWD=$(pwd)

if ops -wsk project deploy --manifest ${PWD}/test-runtimes/manifest.yaml | grep Success
then echo SUCCESS DEPLOY PROJECT;
else echo FAIL DEPLOY PROJECT; exit 1 
fi

if ops -wsk action invoke javascript/hello -r| grep world
then echo SUCCESS JS HELLO;
else echo FAIL JS HELLO; exit 1
fi

if ops -wsk action invoke javascript/redis -r| grep hello
then echo SUCCESS JS REDIS;
else echo FAIL JS REDIS; exit 1 
fi

if ops -wsk action invoke javascript/mongodb -r| grep hello
then echo SUCCESS JS FERRETDB;
else echo FAIL JS FERRETDB; exit 1 
fi

if ops -wsk action invoke javascript/postgres -r| grep 'Nuvolaris Postgres is up and running!'
then echo SUCCESS JS POSTGRES; 
else echo FAIL JS POSTGRES; exit 1 
fi

if ops -wsk action invoke javascript/minio -r| grep "$user-data"
then echo SUCCESS JS MINIO; 
else echo FAIL JS MINIO; exit 1 
fi

if ops -wsk action invoke python/hello -r| grep world
then echo SUCCESS PYTHON HELLO;
else echo FAIL PYTHON HELLO; exit 1
fi

if ops -wsk action invoke python/redis -r| grep world
then echo SUCCESS PYTHON REDIS;
else echo FAIL PYTHON REDIS; exit 1
fi

if ops -wsk action invoke python/mongodb -r| grep world
then echo SUCCESS PYTHON FERRETDB;
else echo FAIL PYTHON FERRETDB; exit 1
fi

if ops -wsk action invoke python/postgres -r| grep 'Nuvolaris Postgres is up and running!'
then echo SUCCESS PYTHON POSTGRES;
else echo FAIL PYTHON POSTGRES; exit 1
fi

if ops -wsk action invoke python/minio -r| grep "$user-data"
then echo SUCCESS PYTHON MINIO; exit 0
else echo FAIL PYTHON MINIO; exit 1
fi
