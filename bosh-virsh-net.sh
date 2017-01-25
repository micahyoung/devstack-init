#!/bin/bash
cat > /tmp/bosh-virsh-net.xml <<EOF
<network>
  <name>bosh</name>
  <dns>
    <forwarder addr="8.8.8.8"/>
  </dns>
  <ip address='172.18.161.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='172.18.161.2' end='172.18.161.254'/>
      <host name='proxy-0'    ip='172.18.161.5' mac='de:ad:be:ef:00:01' />
      <host name='devstack-0' ip='172.18.161.6' mac='de:ad:be:ef:00:02' />
    </dhcp>
  </ip>
</network>
EOF

virsh net-define /tmp/bosh-virsh-net.xml
virsh net-autostart bosh
virsh net-start bosh
