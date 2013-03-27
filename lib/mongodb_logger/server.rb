require 'sinatra/base'
require 'erubis'
require 'multi_json'
require 'active_support'
require 'mustache/sinatra'

require 'mongodb_logger/server/helpers'
require 'mongodb_logger/server/model'
require 'mongodb_logger/server_config'

Encoding.default_external = Encoding::UTF_8 if defined?(Encoding)

module MongodbLogger
  class Server < Sinatra::Base
    module Views; end

    register Mustache::Sinatra
    helpers Sinatra::ViewHelpers
    helpers Sinatra::Partials
    helpers Sinatra::ContentFor

    dir = File.dirname(File.expand_path(__FILE__))

    set :views,         "#{dir}/server/views"
    #set :environment, :production
    set :static, true
    set :mustache, {
      templates: "#{dir}/server/templates",
      views: "#{dir}/server/mustache"
    }

    helpers do
      include Rack::Utils
      include AssetHelpers
      include MustacheHelpers
      alias_method :h, :escape_html
      alias_method :u, :url_path
    end

    before do
      begin
        @main_dir = dir
        @mongo_adapter = (ServerConfig.mongo_adapter ? ServerConfig.mongo_adapter : Rails.logger.mongo_adapter)
        @collection_stats = @mongo_adapter.collection_stats
      rescue => e
        erb :error, {:layout => false}, :error => "Can't connect to MongoDB!"
        return false
      end

      cache_control :private, :must_revalidate, :max_age => 0
    end

    def show(page, layout = true)
      begin
        erb page.to_sym, {:layout => layout}
      rescue => e
        erb :error, { :layout => false }, :error => "Error in view. Debug: #{e.inspect}"
      end
    end

    get "/?" do
      redirect url_path(:overview)
    end

    error do
      erb :error, { :layout => false }, :error => 'Sorry there was a nasty error. Maybe no connection to MongoDB. Debug: ' + env['sinatra.error'].inspect + '<br />' + env.inspect
    end

  end
end

# routes
%w{logs analytic}.each do |route|
  require File.join(File.dirname(File.expand_path(__FILE__)), "server", "routes", route)
end
