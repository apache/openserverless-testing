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
#
import boto3
from botocore.client import Config                                                                                                                                                                   

def main(args):
    buckets = []
    s3 = boto3.resource('s3',
                    endpoint_url=f"http://{args.get('s3_host')}:{args.get('s3_port')}",
                    aws_access_key_id=args.get("s3_access"),
                    aws_secret_access_key=args.get("s3_secret"),
                    config=Config(signature_version='s3v4'),
                    region_name='us-east-1')
                                                                                                                                                                              
    for bucket in s3.buckets.all():
        buckets.append(bucket.name)
    
    response = {"body": buckets}
    return response