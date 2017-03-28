#!/bin/bash

dom_name=devstack-0
if virsh list --all | grep $dom_name; then
  virsh start $dom_name
else
  uvt-kvm create --cpu=4 --memory=57344 --disk=200 --run-script-once=devstack-vm.sh $dom_name arch=amd64 release=xenial
fi
while ! uvt-kvm ip $dom_name; do sleep 1; done
virsh attach-interface $dom_name network bosh --mac de:ad:be:ef:00:02 --model virtio
