<!--
  ~ Licensed to the Apache Software Foundation (ASF) under one
  ~ or more contributor license agreements.  See the NOTICE file
  ~ distributed with this work for additional information
  ~ regarding copyright ownership.  The ASF licenses this file
  ~ to you under the Apache License, Version 2.0 (the
  ~ "License"); you may not use this file except in compliance
  ~ with the License.  You may obtain a copy of the License at
  ~
  ~   http://www.apache.org/licenses/LICENSE-2.0
  ~
  ~ Unless required by applicable law or agreed to in writing,
  ~ software distributed under the License is distributed on an
  ~ "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
  ~ KIND, either express or implied.  See the License for the
  ~ specific language governing permissions and limitations
  ~ under the License.
-->

# OpenServerless testing

Since we are testing in many clouds and environments, test setup is pretty compilcated. Details are in [this document](SETUP.md), please read it carefully...

For the optional SSO backport checks, see [SSO smoke testing](docs/SSO.md).

## Acceptance Test Status: 103/103

<img src="img/progress.svg" width="60%">

|  |               |Kind|M8S |K3S |EKS |AKS |GKE |OSH |
|--|---------------|----|----|----|----|----|----|----|
|1 |Deploy         | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 
|2 |SSL            | N/A| ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
|3 |Sys Redis      | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
|4a|Sys FerretDB   | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 
|4b|Sys Postgres   | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 
|5 |Sys Minio      | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 
|6 |Login          | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 
|7 |Statics        | N/A| ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 
|8 |User Redis     | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 
|9a|User FerretDB  | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
|9b|User Postgres  | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 
|10|User Minio     | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 
|11|Nuv Win        | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
|12|Nuv Mac        | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
|13|We skip this one | N/A | N/A | N/A | N/A | N/A | N/A | N/A |
|14|Runtimes       | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |


