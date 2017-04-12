#!/bin/bash

dom_name=devstack-0
script=devstack-vm.sh
memory_mb=$(expr  56 \* 1024)
disk_gb=300
if virsh list --all | grep $dom_name; then
  virsh start $dom_name
else
cat > uvt-wrapper.sh <<EOF
cat << EOF2 | base64 -d  | tar xJ > $script
$(tar cJ $script | base64 -w0)
EOF2
./$script $(echo $*)
EOF
  uvt-kvm create --cpu=4 --memory=$memory_mb --disk=$disk_gb --run-script-once=uvt-wrapper.sh $dom_name arch=amd64 release=xenial
fi
while ! uvt-kvm ip $dom_name; do sleep 1; done
virsh attach-interface $dom_name network bosh --mac de:ad:be:ef:00:02 --model virtio
