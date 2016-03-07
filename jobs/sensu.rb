#!/usr/bin/env ruby

require 'net/http'
require 'json'

SENSU_API_ENDPOINT = 'http://localhost:4567'

# Set user and password if you want to enable authentication.
# Otherwise, leave them blank.
SENSU_API_USER = ''
SENSU_API_PASSWORD = ''

env_file = File.read('environments.json')
data_hash = JSON.parse(env_file)

columns_file = File.read('columns.json')
columns = JSON.parse(columns_file)


SCHEDULER.every '50s', :first_in => 0 do |job|

  critical_count = 0
  warning_count = 0
  client_warning = Array.new
  client_critical = Array.new
  my_array = []
  hrows = [ { cols: [] } ]

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
  


  def get_assoc(column_name, entry)

    assoc = Hash.new()
    assoc['hostname'] = entry['client']['name'] 
    assoc['check'] = entry['check']['name']
    assoc['output'] = entry['check']['output'] 
    assoc['team'] = entry['check']['team']
    assoc['category'] = entry['check']['category']
  
    return assoc[column_name]
       
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

  columns['config']['default'].each do |column|
    hrows[0][:cols].insert(-1, {class: 'left', value: column})
  end

  events.each_with_index do |event, event_index|
    event_var={cols: []}
    columns['config']['default'].each_with_index do |column, column_index|
      x = get_assoc(column, event)
      if x
        x  =x.chomp
      else
        x = ''
      end
      column_var = {class: 'left', value: x}
      #my_array[event_index]=[]
      #my_array[event_index].insert({cols: {class: 'left', value: x}})
      event_var[:cols].insert(-1, column_var)
      end
      my_array.insert(-1,event_var)
      # my_array.push
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
    crit.each.with_index do |entry, index|

#      columns['config']['default'].each do | column|
#        my_array[index][:cols].insert(-1, {class: 'left', value

#      my_array.push({ cols: [ 
#                    {class: 'left', value: entry['client']['name']}, 
#	                  {class: 'left', value: entry['check']['name']}, 
#                    {class: 'left', value: entry['check']['output']}, 
#                    {class: 'left', value: entry['check']['team']},
#                    {class: 'left', value: entry['check']['category']}
#                            ]} )
      client_critical.push( {:label=>entry['client']['name'], :value=>entry['check']['name'], :poo=>entry['check']['output']} )
    end
  end



  status = "green" 
  if critical_count > 0 
    status = "red"
  elsif warning_count > 0
    status = "yellow"
  end
#hrows = [
#  { cols: [ {class: 'left', value: 'Hostname'}, 
#            {class: 'left', value: 'Check'}, 
#            {class: 'left', value: 'Output'}, 
#            {class: 'left', value: 'team'},
#            {class: 'left', value: 'category'}
# ] }
#]
rows = my_array
 
  send_event('sensu-status', { criticals: critical_count, warnings: warning_count, status: status })
  send_event('sensu-warn-list', { items: client_warning })
  send_event('sensu-crit-list', { items: client_critical })
  send_event('my-table', { hrows: hrows, rows: rows } )
end
