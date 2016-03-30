# Fleximon
A fully customizable UI for Sensu


- [What is Fleximon](#what-is-fleximon)
- [Requirements](#requirements)
- [Features](#features)
- [Running Locally](#running-locally)
- [Running in Production](#running-in-production)
- [License](#license)

## What is Fleximon
Fleximon is a dashboard creating using [dashing](http://dashing.io).
After looking at several other dashboards we couldn't find the features that were required for a multi-team fully customizable dashboard, so we set out to build our own.

## Features
 - Able to filter by team
 - Able to customize columns depending on team
 - able to sort and filter by any column
 - able to change the order of the columns in team-view
 - Clear how many alarms of each type are currently active in the selected view
 - Ability to add new columns that are currently not available in sensu (custom tags etc)
 - Supports multi-environment, multi-datacenter
 - Supports multiple sensu API endpoints and data aggregation
 - Easily customizable

## Requirements
As fleximon is a [dashing](http://dashing.io) dashboard, it is ruby/sinatra with some JavaScript/Coffeescript.  Running bundle install in the root fleximon directory will download and install all required ruby gems.  You will also need to install NodeJS or some other JS interpreter.  Ubuntu is the recommended distribution, although it has been tested on numerous Linux distributions

## Running Locally
Vagrant can be used for running an testing locally.  First install vagrant, and virtualbox then install the vagrant-vbguest and vagrant-hostmanager vagrant plugins. 

```vagrant install <plugin>```

Next clone this repository and run vagrant up fleximon in the root of the directory you just cloned.  You will then be able to ssh into the virtualbox guest and see fleximon running with some dummy alerts.

Sensu is configured in the environment and test alerts are created for different teams and severities.  
All you need to do is start the fleximon service. 

Run...

```bundle exec thin start -R config.ru -e development -p 8080```

from the /vagrant directory.  You can then access the fleximon UI from both inside and outside the VM by going to http://localhost:8080/sensu
Note: if port 8080 is already in use on your host machine then vagrant will assign the next available port.

## Running in Production
to do

## License

This code is open source software licensed under the [GNU General Public License, version 2]("http://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html").
