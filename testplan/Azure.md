# Azure Setup

## Reset Config
ops config reset
#! no cluster expected
ops cloud azcloud vm-list
#! no vm expected

## Create VM k3s
ops cloud azcloud vm-create k3s-test
ops cloud azcloud vm-create mk8s-test
ops cloud azcloud vm-list
#! see the vm

# Dns

ops cloud azcloud zone-create mk8s.opstest.top
ops cloud azcloud zone-create k3s.opstest.top
ops cloud azcloud zone-create k3s-arm.opstest.top
ops cloud azcloud zone-create aks.opstest.top


task k3s:create
task k3s:arm:create


## mk8s
ops cloud azcloud zone-update mk8s.opstest.top --host="*" --vm=mk8s-test

## k3s
ops cloud azcloud zone-update k3s.opstest.top --host="*" --vm=k3s-test

## k3s-arm
ops cloud azcloud zone-update k3s-arm.opstest.top --host="*" --vm=k3s-arm-test

## aks
# IMPORTANT: first retrieve the aks kubeconfig!
# to do this you need access to azure openserverless-testing
ops -config AKS_NAME=aks-test
ops -config AKS_PROJECT=openserverless-testing
ops config use <number> <- replace this with aks-aks-test config number
ops cloud aks lb <- retrieve the ip
ops cloud azcloud zone-update aks.opstest.top --host="*" --ip=<put the ip here>


# Install k3s
ops config reset
KIP=$(ops cloud azcloud vm-getip k3s-test)
ops setup server $KIP ubuntu

# Install mk8s
ops config reset
KIP=$(ops cloud azcloud vm-getip k8s-test)
ops setup cluster
