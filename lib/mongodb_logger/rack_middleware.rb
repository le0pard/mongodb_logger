# Rack middleware for mounted rack app (e.g Grape)
module MongodbLogger
  class RackMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      request = ::Rack::Request.new env
      path = request.path.split('/')
      log_attrs = {:method    => request.request_method,
                :action     => path[2..-1].join('/'),
                :controller => path[1],
                :path       => request.path,
                :url        => request.url,
                :params     => request.params,
                :ip         => env['REMOTE_ADDR']  }

      Rails.logger.mongoize(log_attrs) do
        return @app.call(env)
      end
    end
  end
end