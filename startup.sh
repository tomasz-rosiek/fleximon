#!/bin/bash

# Startup script for Fleximon UI

# Check if config environment variables are set
if [ -n "$FLEXIMON_ENVIRONMENTS" ] && [ -n "$FLEXIMON_COLUMNS" ]; then

	# decode and write config
	echo $FLEXIMON_ENVIRONMENTS | base64 --decode > /app/environments.json
	echo $FLEXIMON_COLUMNS | base64 --decode > /app/columns.json

fi

# start webserver in /app directory
cd /app
bundle exec thin start -R config.ru -e production -p 8080
