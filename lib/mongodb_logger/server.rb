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

    get "/overview/?" do
      @filter = ServerModel::Filter.new(params[:filter])
      @logs = @mongo_adapter.filter_by_conditions(@filter)
      show :overview, !request.xhr?
    end

    # log info
    get "/log/:id" do
      @log = @mongo_adapter.find_by_id(params[:id])
      show :show_log, !request.xhr?
    end

    get "/tail_logs/?:log_last_id?" do
      @info = @mongo_adapter.tail_log_from_params(params)
      @info.merge!(
        :content => @info[:logs].map{ |log| partial(:"shared/log", :object => log) }.join("\n"),
        :collection_stats => partial(:"shared/collection_stats", :object => @collection_stats)
      )
      content_type :json
      MultiJson.dump(@info)
    end

    get "/changed_filter/:type" do
      type_id = ServerModel::AdditionalFilter.get_type_index params[:type]
      conditions = ServerModel::AdditionalFilter::VAR_TYPE_CONDITIONS[type_id]
      values = ServerModel::AdditionalFilter::VAR_TYPE_VALUES[type_id]

      content_type :json
      MultiJson.dump({
        :type_id => type_id,
        :conditions => conditions,
        :values => values
      })
    end

    get "/add_filter/?" do
      @filter = ServerModel::Filter.new(nil)
      @filter_more = ServerModel::AdditionalFilter.new(nil, @filter)
      partial(:"shared/dynamic_filter", :object => @filter_more)
    end

    # analytics
    %w( analytics ).each do |page|
      get "/#{page}/?" do
        @analytic = ServerModel::Analytic.new(@mongo_adapter, params[:analytic])
        show page, !request.xhr?
      end
      post "/#{page}/?" do
        @analytic = ServerModel::Analytic.new(@mongo_adapter, params[:analytic])
        content_type :json
        MultiJson.dump(@analytic.get_data)
      end
    end

    error do
      erb :error, { :layout => false }, :error => 'Sorry there was a nasty error. Maybe no connection to MongoDB. Debug: ' + env['sinatra.error'].inspect + '<br />' + env.inspect
    end

  end
end
