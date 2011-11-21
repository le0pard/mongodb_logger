require 'sinatra/base'
require 'erubis'
require 'json'
require 'active_support'

require 'mongodb_logger/server/view_helpers'
require 'mongodb_logger/server/partials'
require 'mongodb_logger/server/model/filter'
require 'mongodb_logger/server_config'

if defined? Encoding
  Encoding.default_external = Encoding::UTF_8
end

module MongodbLogger
  class Server < Sinatra::Base
    helpers Sinatra::ViewHelpers
    helpers Sinatra::Partials
    
    dir = File.dirname(File.expand_path(__FILE__))

    set :views,         "#{dir}/server/views"
    
    if respond_to? :public_folder
      set :public_folder, "#{dir}/server/public"
    else
      set :public, "#{dir}/server/public"
    end
    #set :environment, :production
    set :static, true

    helpers do
      include Rack::Utils
      alias_method :h, :escape_html
      
      def current_page
        url_path request.path_info.sub('/','')
      end

      def url_path(*path_parts)
        [ path_prefix, path_parts ].join("/").squeeze('/')
      end
      alias_method :u, :url_path

      def path_prefix
        request.env['SCRIPT_NAME']
      end
      
    end
    
    before do
      begin
        if ServerConfig.db && ServerConfig.collection
          @db = ServerConfig.db
          @collection = ServerConfig.collection
        else
          @db = Rails.logger.mongo_connection
          @collection = @db[Rails.logger.mongo_collection_name]
        end
        @collection_stats = @collection.stats
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
        erb :error, {:layout => false}, :error => "Error in view. Debug: #{e.inspect}"
      end
    end


    get "/?" do
      redirect url_path(:overview)
    end

    %w( overview ).each do |page|
      get "/#{page}/?" do
        @filter = MongodbLogger::ServerModel::Filter.new(params[:filter])
        @logs = @collection.find(@filter.get_mongo_conditions).sort('$natural', -1).limit(@filter.get_mongo_limit)
        show page
      end
    end
    
    get "/tail_logs/?:count?" do
      buffer = []
      if params[:count]
        count = params[:count].to_i
        tail = Mongo::Cursor.new(@collection, :tailable => true, :order => [['$natural', 1]]).skip(count)
        while log = tail.next_document
          buffer << partial(:"shared/log", :object => log)
          count += 1
        end
        buffer.reverse!
      else
        count = @collection.count
      end
      content_type :json
      { :count => count, :time => Time.now.getutc, :content => buffer.join("\n") }.to_json
    end
    
    get "/log/:id" do
      @log = @collection.find_one({'_id' => BSON::ObjectId(params[:id])})
      show :show_log, !request.xhr?
    end
    
    get "/log_info/:id" do
      @log = @collection.find_one({'_id' => BSON::ObjectId(params[:id])})
      partial(:"shared/log_info", :object => @log)
    end
    
    error do
      erb :error, {:layout => false}, :error => 'Sorry there was a nasty error. Maybe no connection to MongoDB. Debug: ' + env['sinatra.error'].inspect
    end
    
  end
end
