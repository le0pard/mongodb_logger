module MongodbLogger
  class Server < Sinatra::Base

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

  end
end
