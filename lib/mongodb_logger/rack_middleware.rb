# Rack middleware for mounted rack app (e.g Grape)
module MongodbLogger
  class RackMiddleware
    @@log_attributes_filter = nil

    def self.log_attributes_filter=(filter)
      @@log_attributes_filter = filter
    end

    def initialize(app)
      @app = app
    end
    
    def request_ip(request)
      return request.env["REMOTE_ADDR"]
    end

    def call(env)
      request = ::Rack::Request.new env
      path = request.path.split('/')
      log_attrs = {
        method:     request.request_method,
        action:     (path[2..-1] || []).join('/'),
        controller: path[1],
        path:       request.path,
        url:        request.url,
        params:     request.params,
        ip:         request_ip(request)
      }

      log_attrs = @@log_attributes_filter.call(log_attrs) if @@log_attributes_filter

      @logger ||= if defined?(Rails)
                    Rails.logger
                  elsif defined?(LOGGER)
                    LOGGER
                  else
                    MongodbLogger::Logger.new
                  end

      @logger.mongoize(log_attrs) do
        return @app.call(env)
      end
    end
  end
end
