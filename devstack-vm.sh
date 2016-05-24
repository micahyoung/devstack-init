#!/bin/bash

case `whoami` in

root)
sysctl -w net.ipv4.ip_forward=1
useradd -m -s /bin/bash stack
echo -e "stack ALL=(ALL) NOPASSWD:ALL\nDefaults:stack !requiretty" > /etc/sudoers.d/0-stack
chmod 0777 $0
su -l stack $0
;;

stack)
host_ip=`hostname -I | cut -f1 -d' '`
export http_proxy="http://192.168.1.6:8123"
export https_proxy="http://192.168.1.6:8123"
export no_proxy="127.0.0.1,localhost,$host_ip"
GIT_BASE="https://github.com"

DEBIAN_FRONTEND=noninteractive sudo apt-get -qqy update || sudo yum update -qy
DEBIAN_FRONTEND=noninteractive sudo apt-get install -qqy git || sudo yum install -qy git

sudo chown stack:stack /home/stack
cd /home/stack
git clone --branch=stable/liberty --depth=1 $GIT_BASE/openstack-dev/devstack
cd devstack


echo '[[local|localrc]]'            > local.conf
echo HOST_IP=$host_ip               >> local.conf
echo SERVICE_HOST=$host_ip          >> local.conf
echo MYSQL_HOST=$host_ip            >> local.conf
echo RABBIT_HOST=$host_ip           >> local.conf
echo GLANCE_HOSTPORT=$host_ip:9292  >> local.conf

echo ADMIN_PASSWORD=password >> local.conf
echo DATABASE_PASSWORD=password >> local.conf
echo RABBIT_PASSWORD=password >> local.conf
echo SERVICE_PASSWORD=password >> local.conf
echo SERVICE_TOKEN=password >> local.conf
echo disable_service n-net >> local.conf
echo enable_service q-svc >> local.conf
echo enable_service q-agt >> local.conf
echo enable_service q-dhcp >> local.conf
echo enable_service q-l3 >> local.conf
echo enable_service q-meta >> local.conf
echo enable_service tempest >> local.conf

## Neutron options
echo Q_USE_SECGROUP=True                                                   >> local.conf
echo FLOATING_RANGE="192.168.122.0/24"                                     >> local.conf
echo FIXED_RANGE="10.0.0.0/24"                                             >> local.conf
echo Q_FLOATING_ALLOCATION_POOL=start=192.168.122.250,end=192.168.122.254  >> local.conf
echo PUBLIC_NETWORK_GATEWAY="192.168.122.1" >> local.conf
echo PUBLIC_INTERFACE=eth0 >> local.conf

# Open vSwitch provider networking configuration
echo Q_USE_PROVIDERNET_FOR_PUBLIC=True >> local.conf
echo OVS_PHYSICAL_BRIDGE=br-ex         >> local.conf
echo PUBLIC_BRIDGE=br-ex               >> local.conf
echo OVS_BRIDGE_MAPPINGS=public:br-ex  >> local.conf

# Speedups
echo http_proxy="$http_proxy" >> local.conf
echo https_proxy="$https_proxy" >> local.conf
echo no_proxy="127.0.0.1,localhost,$host_ip" >> local.conf
echo GIT_BASE="$GIT_BASE" >> local.conf


./stack.sh

source openrc
ssh-keygen -t rsa -f id_bosh_rsa -N ''
nova keypair-add --pub-key=id_bosh_rsa.pub --key-type=ssh bosh
neutron security-group-create bosh
neutron security-group-rule-create bosh --protocol=tcp --port-range-min=22    --port-range-max=22    --remote-ip-prefix=0.0.0.0/0
neutron security-group-rule-create bosh --protocol=tcp --port-range-min=22    --port-range-max=22    --remote-ip-prefix=0.0.0.0/0
neutron security-group-rule-create bosh --protocol=tcp --port-range-min=6868  --port-range-max=6868  --remote-ip-prefix=0.0.0.0/0
neutron security-group-rule-create bosh --protocol=tcp --port-range-min=25555 --port-range-max=25555 --remote-ip-prefix=0.0.0.0/0
neutron security-group-rule-create bosh --protocol=tcp --remote-group-id=bosh
neutron security-group-rule-create bosh --protocol=icmp #debugging
neutron floatingip-create public # creates 192.168.122.251
;;

esac

