#!/usr/bin/env ruby

require 'net/http'
require 'json'
require './logging'

app_name = 'fleximon'
$logger = MyLoggerMiddleware.new(STDOUT, app_name)
use MyLoggerMiddleware, $logger

$logger.debug("starting app: %s" % app_name)

begin
  # connection details to environments
  env_file = File.read('environments.json')
  environments = JSON.parse(env_file)

  # columns config for teamviews
  columns_file = File.read('columns.json')
  columns = JSON.parse(columns_file)

rescue Exception => config
  $logger.error('config problems, exiting...', config.class, config.message,
                config.backtrace)
  exit false
end

def get_status(status)
  case status
  when 0
    return 'ok'
  when 1
    return 'warning'
  when 2
    return 'critical'
  else
    return 'unknown'
  end
end

SCHEDULER.every '60s', first_in: 0 do |_job|
  hrows = []
  col_config = []

  # fetch data from sensu API
  def get_data(api, endpoint, user, pass)
    $logger.debug('getting data for %s from %s' % [endpoint, api])
    uri = URI(api + endpoint)
    req = Net::HTTP::Get.new(uri)
    auth = (user.empty? || pass.empty?) ? false : true
    req.basic_auth user, pass if auth
    begin
      response = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req)
      end

    rescue Exception => conn
      $logger.error('Error connecting to %s' % api, conn.class, conn.message,
                    conn.backtrace)
      return
    end

    begin
      JSON.parse(response.body)
    rescue Exception => json_err
      $logger.error('JSON problems', json_err.class, json_err.message,
                    json_err.backtrace)
      return
    end
  end

  # associate column name with hash entry
  def get_assoc(column_name, entry)
    assoc = {}
    assoc['hostname'] = entry['client']['name']
    assoc['name'] = entry['check']['name']
    assoc['output'] = entry['check']['output']
    assoc['team'] = entry['check']['team']
    assoc['status'] = get_status(entry['check']['status'])
    assoc['category'] = entry['check']['category']

    assoc[column_name]
  end

  events = []
  # iterrate through each envionments in the config
  # and pull data for each
  environments['config'].each do |_key, value|
    endpoint = '/events'
    port = value['port']
    user = value['user']
    pass = value['password']
    path = value['path'].nil? ? '' : value['path']
    api = 'http://' + value['host'] + ':' + port + path
    current_env = get_data(api, endpoint, user, pass)
    events.push(*current_env)
  end

  # status = get_data(SENSU_API_ENDPOINT, '/status',

  all_columns = ['hostname', 'status', 'name', 'handlers', 'output', 'history', 'team',
                 'occurances', 'subscribers', 'command']

  all_columns.each do |column|
    hrows.push(column)
  end

  # for each event...
  all_data = []
  events.each_with_index do |event, _event_index|
    status = event['check']['status']
    status_string = get_status(status)
    event_var = { cols: [] }

    # for each column....
    data_list=[]
    all_columns.each_with_index do |column, _column_index|
      data = get_assoc(column, event)
      data = data.nil? ? '' : data.chomp # remove tailing whitespace

      # add column to event var
      column_var = { class: status_string, value: data }
      event_var[:cols].insert(-1, column_var)
      data_list.insert(-1, data)

    end

    # add next row to array
    all_data.insert(-1, data_list)

  end

  # dump data into temporary array to be sorted at runtime
  # depending on team query string provided in URL
  send_event('sensu-table', col_config: columns['config'],
    all_data: all_data, hrows_tmp: hrows)
end
