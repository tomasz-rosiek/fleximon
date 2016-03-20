require 'rack'

# Custom logging class inherits from CommonLogger
class MyLoggerMiddleware < Rack::CommonLogger
  def initialize(app, logger = STDOUT, name)
    @app = app
    @logger = logger
		@name = name
    super(app)
  end

  def call(env)
    if env.key?('SERVER_SOFTWARE') && Sinatra::Base.production?
      @app.call(env)
    else
      began_at = Time.now
      status, header, body = @app.call(env)
      header = Rack::Utils::HeaderHash.new(header)
      body = Rack::BodyProxy.new(body) { log(env, status, header, began_at) }
      [status, header, body]
      super(env)

    end
  end

  FORMAT = %{
    {"app": "%s",
     "Remote Address": "%s",
     "Remote User": "%s",
     "time": "[%s]",
     "method":  "%s",
     "path": "%s",
     "query_string": "%s",
     "http_version": " %s",
     "status_to_s": "%d",
     "length": "%s",
     "begin": "%0.4f"\n}
     }.gsub(/\s+/, ' ').strip

  INFOFORMAT = %{ {"app": "%s", "message": "%s" }  }

  ERRORFORMAT = %{ {"app": "%s", "status": "Error", "message": "%s",
                    "class": "%s", "error": "%s", "backtrace": "%s" }
                 }.gsub(/\s+/,' ').strip

  def error(msg, err_class, err_msg, bt)
    logger = STDOUT
    logger.write ERRORFORMAT % [@name, msg, err_class, err_msg, bt] + "\n"
  end

  def debug(msg)
    # only log debug messages if running in development
    if Sinatra::Base.development?
      info(msg)
    end
  end

  def info(msg)
    logger = STDOUT
    if Sinatra::Base.development?
      logger.write ("INFO: %s\n" % msg)
    else
      logger.write INFOFORMAT % [@name, msg] + "\n"
    end
  end
end
