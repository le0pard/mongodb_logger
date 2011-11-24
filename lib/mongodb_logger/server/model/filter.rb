require 'mongodb_logger/server/model/additional_filter'

module MongodbLogger
  module ServerModel
    class Filter
      
      DEFAULT_LIMIT = 100
      FIXED_PARAMS_ON_FORM = ['action', 'controller', 'ip', 'application_name', 'is_exception', 'limit']
      attr_reader :params, :mongo_conditions
      # dynamic filters
      FORM_NAME = "filter"
      DYNAMIC_NAME = "more"
      attr_accessor :more_filters
      
      def initialize(params)
        FIXED_PARAMS_ON_FORM.each do |key|
          create_variable(key, nil)
        end
        @params = params
        @params.each do |k,v|
          self.send("#{k}=", v) if self.respond_to?(k) && v && !v.blank?
        end unless @params.blank?
        # limits
        self.limit = DEFAULT_LIMIT.to_s if self.limit.nil?
        # dynamic filters
        create_dynamic_filters
        # build mongo conditions
        build_mongo_conditions
      end
      
      def create_variable(k, v)
        self.instance_variable_set("@#{k}", v)  ##  create instance variable
        self.class.send(:define_method, k, proc{self.instance_variable_get("@#{k}")})  ## method to return instance variable
        self.class.send(:define_method, "#{k}=", proc{|v| self.instance_variable_set("@#{k}", v)})  ## method to set instance variable
      end
      
      def create_dynamic_filters
        self.more_filters = []
        @params[DYNAMIC_NAME].each do |filter|
          self.more_filters << AdditionalFilter.new(filter)
        end if !@params.blank? && @params[DYNAMIC_NAME] && !@params[DYNAMIC_NAME].blank?
      end
      
      def build_mongo_conditions
        @mongo_conditions = Hash.new
        FIXED_PARAMS_ON_FORM.each do |param_key|
          value = self.send param_key
          mkey_val = case param_key
          when 'is_exception'
            (value ? true : nil)
          when 'limit'
            nil # skip
          else
            value
          end
          @mongo_conditions[param_key.to_s] = mkey_val if !mkey_val.nil? && !mkey_val.blank?
        end
      end
      
      def get_mongo_conditions
        @mongo_conditions
      end
      
      def get_mongo_limit
        self.limit.to_i
      end
      
      def form_name
        FORM_NAME
      end
      
    end
  end
end