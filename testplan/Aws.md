# AWS

## Reset Config
ops config reset
ops cloud aws vm-list
#! error!
task aws:config
ops cloud aws vm-list
#! show list of vms (none)

## Create VM k3s
ops cloud aws vm-create k3s-test
ops cloud aws vm-create mk8s-test
ops cloud aws vm-list
#! see the vm 

# Install k3s
KIP=$(ops cloud aws vm-getip k3s-test)
ops cloud k3s create $KIP ubuntu
ops config use

## Install microk8s
MIP=$(ops cloud aws vm-getip mk8s-test)
ops cloud mk8s create $MIP ubuntu
ops config use

# recover config
ops config reset
task aws:config
ops config use
ops cloud k3s kubeconfig $KIP ubuntu
ops config use
ops cloud mk8s kubeconfig $MIP ubuntu
ops config use

# Delete
ops cloud mk8s delete $MIP ubuntu
ops config use
ops cloud k3s delete $KIP ubuntu
ops config use

## Delete VMs
ops cloud aws vm-delete k3s-test
ops cloud aws vm-delete mk8s-test
ops cloud aws vm-list
