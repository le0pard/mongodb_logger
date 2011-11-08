require 'sinatra/base'
require 'erb'
require 'time'

if defined? Encoding
  Encoding.default_external = Encoding::UTF_8
end

module MongodbLogger
  class Server < Sinatra::Base
    dir = File.dirname(File.expand_path(__FILE__))

    set :views,         "#{dir}/server/views"
    set :public_folder, "#{dir}/server/public"

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
        # do something
      end
    end

    def show(page, data, layout = true)
      response["Cache-Control"] = "max-age=0, private, must-revalidate"
      begin
        @logs = data['logs']
        erb page.to_sym, {:layout => layout}
      rescue Errno::ECONNREFUSED
        erb :error, {:layout => false}, :error => "Can't connect to MongoDB!"
      end
    end


    get "/?" do
      redirect url_path(:overview)
    end

    %w( overview ).each do |page|
      get "/#{page}" do
        @logs = @collection.find().sort('$natural', -1).limit(2000)
        show(page, {'logs' => @logs})
      end
    end
    
    # application js
    get '/application.js' do
      coffee :application
    end
    
  end
end