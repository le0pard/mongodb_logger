require 'sinatra/base'
require 'erubis'
require 'json'
require 'mongodb_logger/server/partials'
require 'mongodb_logger/server/model/filter'
require 'mongodb_logger/server_config'

if defined? Encoding
  Encoding.default_external = Encoding::UTF_8
end

module MongodbLogger
  class Server < Sinatra::Base
    helpers Sinatra::Partials
    
    dir = File.dirname(File.expand_path(__FILE__))

    set :views,         "#{dir}/server/views"
    
    if respond_to? :public_folder
      set :public_folder, "#{dir}/server/public"
    else
      set :public, "#{dir}/server/public"
    end

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
      
      def get_field_val(key)
        return MongodbLogger::ServerModel::Filter::DEFAULT_LIMIT if !@filter_model && "limit" == key
        @filter_model ? @filter_model.get_val(key) : nil
      end
      
      def select_tag(name, values, selected = nil)
        selector = ["<select name=#{name}>"]
        values.each do |val|
          selector << "<option value='#{val}' #{"selected='selected'" if val.to_s == selected.to_s}>#{val}</option>"
        end
        selector << "</select>"
        selector.join("\n")
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
      rescue => e
        erb :error, {:layout => false}, :error => "Can't connect to MongoDB!"
        return false
      end
    end

    def show(page, layout = true)
      response["Cache-Control"] = "max-age=0, private, must-revalidate"
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
        if params[:f]
          @filter_model = MongodbLogger::ServerModel::Filter.new(params[:f])
          @logs = @collection.find(@filter_model.get_conditions).limit(@filter_model.get_limit)
        else
          @logs = @collection.find.limit(MongodbLogger::ServerModel::Filter::DEFAULT_LIMIT)
        end
        @logs = @logs.sort('$natural', -1)
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
    
  end
end
