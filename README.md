## DevStack init

```shell
uvt-kvm create --memory=10240 --disk=60 --cpu=4 --run-script-once=devstack-vm.sh devstack-0 arch=amd64 release=trusty
while ! uvt-kvm ip devstack-0; do sleep 1; done
./devstack-net.sh
```
