require 'sinatra/base'
require 'erubis'
require 'json'
require 'mongodb_logger/server/partials'

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
    end
    
    before do
      begin
        @db = Rails.logger.mongo_connection
        @collection = @db[Rails.logger.mongo_collection_name]
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
      get "/#{page}" do
        @logs = @collection.find().sort('$natural', -1).limit(2000)
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
      { :count => count, :content => buffer.join("\n") }.to_json
    end
    
    get "/log/:id" do
      @log = @collection.find_one({'_id' => BSON::ObjectId(params[:id])})
      show :show_log, !request.xhr?
    end
    
    # application js
    get '/application.js' do
      content_type 'text/javascript'
      coffee :application
    end
    
  end
end