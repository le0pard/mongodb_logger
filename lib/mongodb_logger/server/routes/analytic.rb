module MongodbLogger
  class Server < Sinatra::Base

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
  end
end
