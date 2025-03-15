# Docker setup

## Reset 
ops config reset

ops setup docker status
#! no cluster expected

### Create cluster
ops setup docker create
ops setup docker status
#! one cluster
ops debug kinfo
#! one cluster
ops config use
#! find kubeconfig kind

## Kubeconfig
ops config reset
ops config use
ops setup docker kubeconfig
ops config use
#! remove and recover kubeconfig

### Delete cluster
ops setup docker delete
ops setup docker status
#! no cluster