#!/usr/bin/env ruby

require 'net/http'
require 'json'

SENSU_API_ENDPOINT = 'http://localhost:4567'.freeze

# Set user and password if you want to enable authentication.
# Otherwise, leave them blank.
SENSU_API_USER = ''.freeze
SENSU_API_PASSWORD = ''.freeze

env_file = File.read('environments.json')
data_hash = JSON.parse(env_file)

columns_file = File.read('columns.json')
columns = JSON.parse(columns_file)

SCHEDULER.every '50s', first_in: 0 do |_job|
  critical_count = 0
  warning_count = 0
  client_warning = []
  client_critical = []
  my_array = []
  hrows = [{ cols: [] }]

  # auth = (SENSU_API_USER.empty? || SENSU_API_PASSWORD.empty?) ? false : true

  def get_data(api, endpoint, user, pass)
    uri = URI(api + endpoint)
    req = Net::HTTP::Get.new(uri)
    auth = (user.empty? || pass.empty?) ? false : true
    req.basic user, pass if auth
    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end
    JSON.parse(response.body)
  end

  def get_assoc(column_name, entry)
    assoc = {}
    assoc['hostname'] = entry['client']['name']
    assoc['check'] = entry['check']['name']
    assoc['output'] = entry['check']['output']
    assoc['team'] = entry['check']['team']
    assoc['category'] = entry['check']['category']

    assoc[column_name]
  end

  data_hash['config'].each do |_key, value|
    endpoint = '/events'
    port = value['port']
    api = 'http://' + value['host'] + ':' + port
    user = value['user']
    pass = value['password']
    get_data(api, endpoint, user, pass)
  end

  warn = []
  crit = []

  events = get_data(SENSU_API_ENDPOINT, '/events',
                    SENSU_API_USER, SENSU_API_PASSWORD)
  # status = get_data(SENSU_API_ENDPOINT, '/status',
  # SENSU_API_USER, SENSU_API_PASSWORD)

  columns['config']['default'].each do |column|
    hrows[0][:cols].insert(-1, class: 'left', value: column)
  end

  events.each_with_index do |event, _event_index|
    event_var = { cols: [] }
    columns['config']['default'].each_with_index do |column, _column_index|
      x = get_assoc(column, event)
      x = if x
            x.chomp
          else
            ''
          end
      column_var = { class: 'left', value: x }
      event_var[:cols].insert(-1, column_var)
    end
    my_array.insert(-1, event_var)
    status = event['check']['status']
    if status == 1
      warn.push(event)
      warning_count += 1
    elsif status == 2
      crit.push(event)
      critical_count += 1
    end
  end

  unless warn.empty?
    warn.each do |entry|
      client_warning.push(label: entry['client']['name'],
                          value: entry['check']['name'],
                          poo: entry['check']['output'])
    end
  end
  unless crit.empty?
    crit.each.with_index do |entry, _index|
      client_critical.push(label: entry['client']['name'],
                           value: entry['check']['name'],
                           poo: entry['check']['output'])
    end
  end

  status = 'green'
  if critical_count > 0
    status = 'red'
  elsif warning_count > 0
    status = 'yellow'
  end

  rows = my_array

  send_event('sensu-status', criticals: critical_count,
                             warnings: warning_count, status: status)
  send_event('sensu-warn-list', items: client_warning)
  send_event('sensu-crit-list', items: client_critical)
  send_event('my-table', hrows: hrows, rows: rows)
end
