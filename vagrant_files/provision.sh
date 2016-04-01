#!/usr/bin/env bash

# Bootstrap script for fleximon in vagrant
# Installs sensu, and configures 100 random alarms
# then runs fleximon on port 8080

set -ou pipefail

# Add repositories for sensu
sensu_repo() {
  wget -q http://repositories.sensuapp.org/apt/pubkey.gpg -O- | \
    sudo apt-key add -
  echo "deb     http://repositories.sensuapp.org/apt sensu main" > \
    /etc/apt/sources.list.d/sensu.list
}

# Install sensu and dependencies
# uchiwa installed for debug and comparision purposes
package_install() {
  sensu_repo
  apt-get update
  apt-get -y install redis-server sensu nodejs rabbitmq-server uchiwa bundler
}

# configure rabbitmq
configure_rabbit() {
  package_install
  rabbitmqctl add_vhost /sensu
  rabbitmqctl add_user sensu sensu
  rabbitmqctl set_permissions -p /sensu sensu ".*" ".*" ".*"
}

# create 100 random sensu alerts and create service config
create_alerts() {
  configure_rabbit
  cp /etc/sensu/config.json.example /etc/sensu/config.json
# Remove all previous test-*.json file previous generated on vagrant provision run.
  cd /etc/sensu/conf.d/
  rm -f test-*.json
  # Generate test events.
  /vagrant/vagrant_files/replicate.py
}

# restart all sensu services
service_restart() {
  create_alerts
  for service in client server api; do
    /etc/init.d/sensu-service $service restart
  done
}

bundle_install() {
  cd /vagrant
  su vagrant -c bundle install
}

# configure and start fleximon on port 8080
start_fleximon() {
  bundle_install
  cd /vagrant
  if [[ -e columns.json ]]; then
    echo "File colums.json already exist"
  else
    cp columns.json.example columns.json
  fi

  if [[ -e environments.json ]]; then
    echo "File envionments.json already exist"
  else
    cp environments.json.example environments.json
  fi

  su -c 'nohup bundle exec thin start -R config.ru -e development -p 8080 0<&- &>> /vagrant/fleximon.log &' vagrant
}

main() {
  service_restart
  start_fleximon
}

main

exit 0
