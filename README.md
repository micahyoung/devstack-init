## DevStack init

```shell
sudo sysctl -w net.ipv4.ip_forward=1     # also add to /etc/sysctl
sudo apt install uvtool-libvirt
# log out and back in
ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''

uvt-simplestreams-libvirt sync --verbose release=xenial arch=amd64
uvt-kvm create --memory=10240 --disk=60 --cpu=4 --run-script-once=devstack-vm.sh devstack-0 arch=amd64 release=xenial
while ! uvt-kvm ip devstack-0; do sleep 1; done
./devstack-net.sh
```


