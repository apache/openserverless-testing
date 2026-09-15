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
