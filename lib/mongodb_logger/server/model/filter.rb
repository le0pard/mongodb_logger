module MongodbLogger
  module ServerModel
    class Filter
      
      DEFAULT_LIMIT = 2000
      FIXED_PARAMS = ['action', 'controller', 'ip', 'application_name', 'is_exception']
      attr_reader :params, :mongo_conditions, :mongo_limit
      
      def initialize(params)
        if params.nil?
          params = Hash.new
          FIXED_PARAMS.each do |key|
            params[key] = nil
          end
        end
        @params = params
        params.each do |k,v|
          self.instance_variable_set("@#{k}", v)  ##  create instance variable
          self.class.send(:define_method, k, proc{self.instance_variable_get("@#{k}")})  ## method to return instance variable
          self.class.send(:define_method, "#{k}=", proc{|v| self.instance_variable_set("@#{k}", v)})  ## method to set instance variable
        end
        
        if !self.respond_to?("limit")
          self.instance_variable_set("@limit", DEFAULT_LIMIT.to_s)  ##  create instance variable
          self.class.send(:define_method, "limit", proc{self.instance_variable_get("@limit")})  ## method to return instance variable
          self.class.send(:define_method, "limit=", proc{|v| self.instance_variable_set("@limit", DEFAULT_LIMIT.to_s)})  ## method to set instance variable
        elsif self.limit.nil?
          self.limit = DEFAULT_LIMIT.to_s
        end 
        build_mongo_conditions
      end
      
      def build_mongo_conditions
        @mongo_conditions = Hash.new
        FIXED_PARAMS.each do |param_key| 
          if self.respond_to?(param_key)
            value = self.send param_key
            if 'is_exception' == param_key
              @mongo_conditions[param_key.to_s] = true if value && !value.blank?
            else
              @mongo_conditions[param_key.to_s] = value unless value.blank?
            end
          end
        end
        # set limit
        @mongo_limit = DEFAULT_LIMIT
        @mongo_limit = self.limit.to_i if self.respond_to?("limit")
      end
      
      def get_mongo_conditions
        @mongo_conditions
      end
      
      def get_mongo_limit
        @mongo_limit
      end
      
      def form_name
        "filter"
      end
      
    end
  end
end