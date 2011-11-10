module MongodbLogger
  module ServerModel
    class Filter
      
      DEFAULT_LIMIT = 2000
      FIXED_PARAMS = ['action', 'controller', 'ip', 'application_name']
      attr_reader :params, :mongo_conditions
      
      def initialize(params)
        @params = params
        build_mongo_conditions
      end
      
      def build_mongo_conditions
        @mongo_conditions = Hash.new
        FIXED_PARAMS.each do |param_key| 
          @mongo_conditions[param_key] = @params[param_key] unless @params[param_key].blank?
        end
      end
      
      def get_conditions
        @mongo_conditions
      end
      
      def get_val(key)
        (@params[key] && !@params[key].blank?) ? @params[key] : nil
      end
      
      def get_limit
        limit = @params['limit'].to_i
        limit = DEFAULT_LIMIT if !limit || (limit && (limit < 1 || limit > 10000))
        limit
      end
      
    end
  end
end