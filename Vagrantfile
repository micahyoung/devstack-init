# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/trusty64"
  config.vm.box_check_update = false
  config.vm.hostname = "devstack-0"
  config.vm.network "private_network", ip: "172.18.161.6"

  config.vm.provider "virtualbox" do |vb|
    vb.cpus = 4
    vb.memory = 10_240
    vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"] # private_network eth1
  end

  # config.ssh.pty = true
  config.vm.provision "file", source: "./devstack-vm.sh", destination: "/tmp/devstack-vm.sh"
  config.vm.provision :shell, :inline => "bash /tmp/devstack-vm.sh", :privileged => true
end
