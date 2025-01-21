# OpenServerless testing

Since we are testing in many clouds and environments, test setup is pretty compilcated. Details are in [this document](SETUP.md), please read it carefully...

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


