require 'dashing'
require 'logger'
require 'rack/body_proxy'
require 'json'
require './logging'
set :logging, false
Logger.class_eval { alias :write :'<<' }
logger = MyLoggerMiddleware.new(STDOUT, 'fleximon')
use MyLoggerMiddleware, logger

logger.info('Created logger')

configure do
  set :auth_token, 'YOUR_AUTH_TOKEN'
  helpers do
    def protected!
      # Put any authentication code you want in here.
      # This method is run before accessing any resource.
    end
  end
end

map Sinatra::Application.assets_prefix do
  run Sinatra::Application.sprockets
end

run Sinatra::Application
