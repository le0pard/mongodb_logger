module MongodbLogger
  module Filter
    def self.included(base)
      base.class_eval { around_filter :enable_mongodb_logger }
    end

    def enable_mongodb_logger
      return yield unless Rails.logger.respond_to?(:mongoize)
      f_params = case
                   when request.respond_to?(:filtered_parameters) then request.filtered_parameters
                   else params
                 end
      Rails.logger.mongoize({
        :action         => action_name,
        :controller     => controller_name,
        :path           => request.path,
        :url            => request.url,
        :params         => f_params,
        :ip             => request.remote_ip
      }) { yield }
    end
  end
end
