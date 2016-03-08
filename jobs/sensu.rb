#!/usr/bin/env ruby

require 'net/http'
require 'json'

# Set user and password if you want to enable authentication.
# Otherwise, leave them blank.
SENSU_API_USER = ''.freeze
SENSU_API_PASSWORD = ''.freeze
SENSU_API_ENDPOINT = 'http://localhost:4567'.freeze

# connection details to environments
env_file = File.read('environments.json')
environments = JSON.parse(env_file)

# columns config for teamviews
columns_file = File.read('columns.json')
columns = JSON.parse(columns_file)

SCHEDULER.every '50s', first_in: 0 do |_job|
  critical_count = 0
  warning_count = 0
  unknown_count = 0
  client_warning = []
  client_critical = []
  table_data = []
  hrows = [{ cols: [] }]

  # fetch data from sensu API
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

  # associate column name with hash entry
  def get_assoc(column_name, entry)
    assoc = {}
    assoc['hostname'] = entry['client']['name']
    assoc['check'] = entry['check']['name']
    assoc['output'] = entry['check']['output']
    assoc['team'] = entry['check']['team']
    assoc['category'] = entry['check']['category']

    assoc[column_name]
  end

  # iterrate through each envionments in the config
  # and pull data for each
  environments['config'].each do |_key, value|
    endpoint = '/events'
    port = value['port']
    user = value['user']
    pass = value['password']
    api = 'http://' + value['host'] + ':' + port
    get_data(api, endpoint, user, pass)
  end

  warn = []
  crit = []

  # get hash
  events = get_data(SENSU_API_ENDPOINT, '/events',
                    SENSU_API_USER, SENSU_API_PASSWORD)
  # status = get_data(SENSU_API_ENDPOINT, '/status',
  # SENSU_API_USER, SENSU_API_PASSWORD)

  columns['config']['default'].each do |column|
    hrows[0][:cols].insert(-1, class: 'left', value: column)
  end

  # for each event...
  events.each_with_index do |event, _event_index|
    event_var = { cols: [] }

    # for each column....
    columns['config']['default'].each_with_index do |column, _column_index|
      data = get_assoc(column, event)
      data = data.nil? ? '' : data.chomp # remove tailing whitespace

      # add column to event var
      column_var = { class: 'left', value: data }
      event_var[:cols].insert(-1, column_var)
    end
    # add complete row
    table_data.insert(-1, event_var)

    # increment alarm count for different status type
    status = event['check']['status']
    if status == 1
      warn.push(event)
      warning_count += 1
    elsif status == 2
      crit.push(event)
      critical_count += 1
    elsif status > 2 # status 3 and above == unknown
      unknown_count += 1
    end
  end

  # update warning count
  unless warn.empty?
    warn.each do |entry|
      client_warning.push(label: entry['client']['name'],
                          value: entry['check']['name'])
    end
  end

  # update critical count
  unless crit.empty?
    crit.each.with_index do |entry, _index|
      client_critical.push(label: entry['client']['name'],
                           value: entry['check']['name'])
    end
  end

  status = if critical_count > 0
             'red'
           elsif warning_count > 0
             'yellow'
           else
             'green'
           end

  # Send all collected data to dashboard
  send_event('sensu-status',
             criticals: critical_count,
             warnings: warning_count,
             unknowns: unknown_count,
             status: status)

  send_event('sensu-warn-list', items: client_warning)
  send_event('sensu-crit-list', items: client_critical)
  send_event('sensu-table', hrows: hrows, rows: table_data)
end
