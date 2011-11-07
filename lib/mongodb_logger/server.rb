require 'sinatra/base'
require 'erb'
require 'time'

if defined? Encoding
  Encoding.default_external = Encoding::UTF_8
end

module MongodbLogger
  class Server < Sinatra::Base
    dir = File.dirname(File.expand_path(__FILE__))

    set :views,  "#{dir}/server/views"
    set :public, "#{dir}/server/public"

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
      @db = Rails.logger.mongo_connection
      @collection = @db[Rails.logger.mongo_collection_name]
    end

    def show(page, data, layout = true)
      response["Cache-Control"] = "max-age=0, private, must-revalidate"
      begin
        @logs = data['logs']
        haml page.to_sym, {:layout => layout}
      rescue Errno::ECONNREFUSED
        haml :error, {:layout => false}, :error => "Can't connect to MongoDB!"
      end
    end


    get "/?" do
      redirect url_path(:overview)
    end

    %w( overview ).each do |page|
      get "/#{page}" do
        @logs = @collection.find().sort('$natural', -1).limit(100)
        show(page, {'logs' => @logs})
      end
    end
    
    # main css
    get '/main.css' do
      content_type 'text/css', :charset => 'utf-8'
      sass :main, :layout => false, :cache_location => File.join(Rails.root, "tmp/")
    end
    
    # application js
    get '/application.js' do
      coffee :application
    end
    
  end
end