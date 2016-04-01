# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/wily64"

  config.vm.provider "virtualbox" do |vb|
    vb.cpus = 2
    vb.memory = 768
  end

  config.vm.define :fleximon do |srv|
    srv.vm.hostname = "fleximon"
    srv.vm.network "forwarded_port", guest: 8080, host: 8080,
      auto_correct: true
    srv.vm.provision "shell", inline: "/vagrant/vagrant_files/provision.sh"
  end

end
