# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/wily64"

  config.vm.provider "virtualbox" do |vb|
    vb.cpus = 2
  end

  config.vm.network "private_network", type: "dhcp"

  config.hostmanager.enabled = true
  config.hostmanager.ip_resolver = proc do |vm, resolving_vm|
    if vm.id
      `VBoxManage guestproperty get #{vm.id} \
        "/VirtualBox/GuestInfo/Net/1/V4/IP"`.split()[1]
    end
  end

  config.vm.define :fleximon do |srv|
    srv.vm.hostname = "fleximon"
    srv.vm.network "forwarded_port", guest: 8080, host: 8080,
      auto_correct: true
    srv.vm.provision "shell", inline: "/vagrant/vagrant_files/provision.sh"
  end

end
