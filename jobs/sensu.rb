#!/usr/bin/env ruby

require 'net/http'
require 'json'

SENSU_API_ENDPOINT = 'http://localhost:4567'

# Set user and password if you want to enable authentication.
# Otherwise, leave them blank.
SENSU_API_USER = ''
SENSU_API_PASSWORD = ''

file = File.read('environments.json')
data_hash = JSON.parse(file)


SCHEDULER.every '50s', :first_in => 0 do |job|

  critical_count = 0
  warning_count = 0
  client_warning = Array.new
  client_critical = Array.new
  my_array = []
  auth = (SENSU_API_USER.empty? || SENSU_API_PASSWORD.empty?) ? false : true

  def get_data(api, endpoint, user, pass)
    uri = URI(api + endpoint)
    req = Net::HTTP::Get.new(uri)
    auth = (user.empty? || pass.empty?) ? false : true
    req.basic user, pass if auth
    response = Net::HTTP.start(uri.hostname, uri.port) {|http|
      http.request(req)
    }
    return JSON.parse(response.body)
  end

data_hash['config'].each do |key, value|
  endpoint = "/events"
  port = value['port']
  api = "http://" + value['host'] + ":" + port
  user = value['user']
  pass = value['password']
  get_data(api, endpoint, user, pass)
end

  
  #uri = URI(SENSU_API_ENDPOINT+"/events")
  #req = Net::HTTP::Get.new(uri)
  #req.basic_auth SENSU_API_USER, SENSU_API_PASSWORD if auth
  #response = Net::HTTP.start(uri.hostname, uri.port) {|http|
  #  http.request(req)
  #}

  warn = Array.new
  crit = Array.new

  #events = JSON.parse(response.body)
  events = get_data(SENSU_API_ENDPOINT, '/events', SENSU_API_USER, SENSU_API_PASSWORD)
  #status = get_data(SENSU_API_ENDPOINT, '/status', SENSU_API_USER, SENSU_API_PASSWORD)
  events.each do |event|
    status = event['check']['status']
    if status == 1
      warn.push(event)
      warning_count += 1
    elsif status == 2
      crit.push(event)
      critical_count += 1
    end
  end
  if !warn.empty?
    warn.each do |entry|
      #my_array.insert('a', 'b', 'c')
      client_warning.push( {:label=>entry['client']['name'], :value=>entry['check']['name'], :poo=>entry['check']['output']} )
    end
  end
  if !crit.empty?
    crit.each do |entry|
      my_array.push({ cols: [ {class: 'left', value: entry['client']['name']}, 
	                  {class: 'left', value: entry['check']['name']}, 
                    {class: 'left', value: entry['check']['output']}, 
                    {class: 'left', value: entry['check']['team']},
                    {class: 'left', value: entry['check']['category']}]} )
      client_critical.push( {:label=>entry['client']['name'], :value=>entry['check']['name'], :poo=>entry['check']['output']} )
    end
  end

  status = "green" 
  if critical_count > 0 
    status = "red"
  elsif warning_count > 0
    status = "yellow"
  end
hrows = [
  { cols: [ {class: 'left', value: 'Hostname'}, 
            {class: 'left', value: 'Check'}, 
            {class: 'left', value: 'Output'}, 
            {class: 'left', value: 'team'},
            {class: 'left', value: 'category'}
 ] }
]
rows = my_array
 
  send_event('sensu-status', { criticals: critical_count, warnings: warning_count, status: status })
  send_event('sensu-warn-list', { items: client_warning })
  send_event('sensu-crit-list', { items: client_critical })
  send_event('my-table', { hrows: hrows, rows: rows } )
end
