#!/usr/bin/env bash

# Bootstrap script for fleximon in vagrant
# Installs sensu, and configures 100 random alarms
# then runs fleximon on port 8080

set -eu

# Add repositories for sensu
wget -q http://repositories.sensuapp.org/apt/pubkey.gpg -O- | \
  sudo apt-key add -
echo "deb     http://repositories.sensuapp.org/apt sensu main" > \
  /etc/apt/sources.list.d/sensu.list
apt-get update

# Install sensu and dependencies
# uchiwa installed for debug and comparision purposes
apt-get -y install redis-server sensu nodejs rabbitmq-server uchiwa

# configure rabbitmq
rabbitmqctl add_vhost /sensu
rabbitmqctl add_user sensu sensu
rabbitmqctl set_permissions -p /sensu sensu ".*" ".*" ".*"

# create 100 random sensu alerts and create service config
rm -f /etc/sensu/conf.d/test-*.json; /vagrant/vagrant_files/replicate.py
mv /etc/sensu/config.json.example /etc/sensu/config.json

# restart all sensu services
for service in client server api; do
  /etc/init.d/sensu-service $service restart
done

mv /vagrant/columns.json.example /vagrant/columns.json
mv /vagrant/environments.json.example /vagrant/environments.json
# configure and start fleximon on port 8080
su vagrant -c 'cd /vagrant; bundle install;
  nohup bundle exec thin start -R config.ru -e development -p 8080' &

exit 0
