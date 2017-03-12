#!/bin/bash
set -ex

case `whoami` in

root)
network_interface=ens7
# change ubuntu password for console access
echo -e "ubuntu\nubuntu" | sudo passwd ubuntu

# set up bosh network interface
cat > /etc/network/interfaces.d/bosh.cfg <<EOF
auto $network_interface
iface $network_interface inet dhcp
EOF

# bring interface up, if not already
ifup $network_interface

# set up stack user
useradd -m -s /bin/bash stack
echo -e "stack ALL=(ALL) NOPASSWD:ALL\nDefaults:stack !requiretty" > /etc/sudoers.d/0-stack
chmod 0777 $0
su -l stack $0
;;

stack)
host_ip="172.18.161.6"
proxy_ip="172.18.161.5"
network_interface=ens7
export http_proxy="http://$proxy_ip:8123"
export https_proxy="http://$proxy_ip:8123"
export no_proxy="127.0.0.1,localhost,$host_ip,$proxy_ip"
#GIT_BASE="http://s3.amazonaws.com/openstack-liberty-cache"
GIT_BASE="https://github.com"

DEBIAN_FRONTEND=noninteractive sudo apt-get -qqy update || sudo yum update -qy
DEBIAN_FRONTEND=noninteractive sudo apt-get install -qqy git || sudo yum install -qy git

sudo chown stack:stack /home/stack
cd /home/stack
git clone --branch=stable/newton $GIT_BASE/openstack-dev/devstack.git
cd devstack

cat > local.conf <<EOF
[[local|localrc]]
HOST_IP=$host_ip
SERVICE_HOST=$host_ip
MYSQL_HOST=$host_ip
RABBIT_HOST=$host_ip
GLANCE_HOSTPORT=$host_ip:9292

ADMIN_PASSWORD=password
DATABASE_PASSWORD=password
RABBIT_PASSWORD=password
SERVICE_PASSWORD=password
SERVICE_TOKEN=password

# Services:
## Enable Neutron networking
disable_service n-net
enable_service q-svc
enable_service q-agt
enable_service q-dhcp
enable_service q-l3
enable_service q-meta

## Neutron options
Q_USE_SECGROUP=True
FLOATING_RANGE="172.18.161.0/24"
FIXED_RANGE="10.0.0.0/24"
Q_FLOATING_ALLOCATION_POOL=start=172.18.161.250,end=172.18.161.254
PUBLIC_NETWORK_GATEWAY=172.18.161.1
PUBLIC_INTERFACE=$network_interface

# Open vSwitch provider networking configuration
Q_USE_PROVIDERNET_FOR_PUBLIC=True
OVS_PHYSICAL_BRIDGE=br-ex
PUBLIC_BRIDGE=br-ex
OVS_BRIDGE_MAPPINGS=public:br-ex

# Speedups
http_proxy="$http_proxy"
https_proxy="$https_proxy"
no_proxy="127.0.0.1,localhost,$host_ip,$proxy_ip"
GIT_BASE="$GIT_BASE"
EOF

./stack.sh

source ./openrc admin demo

cat > id_bosh_rsa.pub <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDjiROOp2ClfiN0/9k+le/jMqHTI0/akgggCZ2hDf9aGhNFaVwdnU/yrKtCIobYv6LPX/uwQBwXUgWQ5ezlffe79RWJs7OQYEsN8aOSlqcBqfap0f2K0sQpU9jYvJuUdOw/pzpHAGo5yFlW8oCSJke/DU3LGqJkw/CVOCq1pohczVgYiBia0Un4l9CceT22bb2ZxMfy26jw0VtX4cC2UtVyfXI9xjaqbzFCJwQcIe8ECom0e7RLF0aglCSs+gwoRg/HK7NjnFPLVL0CuB4aBD+B6eLtI0LxB1ixcsnRi/UXeLFKfs+jwysUEgcN1H5pY8N/X44yNQ+OkMXZ/7PwpH/d vcap@bosh-init 
EOF

openstack keypair create --public-key=id_bosh_rsa.pub bosh

openstack security group create bosh
openstack security group rule create bosh --protocol=tcp --dst-port=22
openstack security group rule create bosh --protocol=tcp --dst-port=6868
openstack security group rule create bosh --protocol=tcp --dst-port=25555
openstack security group rule create bosh --protocol=tcp --src-group=bosh
openstack security group rule create bosh --protocol=udp --src-group=bosh
openstack security group rule create bosh --protocol=icmp #debugging
openstack floating ip create public --floating-ip-address 172.18.161.251

#Concourse
openstack security group rule create bosh --protocol=tcp --dst-port=8080
openstack floating ip create public --floating-ip-address 172.18.161.250

#Create minimal flavor
# - ephemeral disk is 5G since defaults are insufficient: bosh will use 1GB for swap and the rest is for /var/vcap/data
openstack flavor create m1.lite --public --vcpus 1 --ram 1024 --disk 5
openstack flavor create m1.feather --public --vcpus 1 --ram 2048 --disk 5

#output private net uuid
openstack network show private -c id
;;

esac

