require 'mongodb_logger/server/model/additional_filter'

module MongodbLogger
  module ServerModel
    class Filter < Base

      DEFAULT_LIMIT = 100
      FIXED_PARAMS_ON_FORM = ['action', 'controller', 'ip', 'application_name', 'is_exception', 'limit']
      attr_reader :params, :mongo_conditions
      # dynamic filters
      FORM_NAME = "filter"
      attr_accessor :more_filters

      def initialize(params)
        FIXED_PARAMS_ON_FORM.each do |key|
          create_variable(key, nil)
        end
        @params = params
        set_params_to_methods
        # limits
        self.limit = DEFAULT_LIMIT.to_s if self.limit.nil?
        # dynamic filters
        create_dynamic_filters
        # build mongo conditions
        build_mongo_conditions
      end

      def create_dynamic_filters
        self.more_filters = []
        @params[AdditionalFilter::FORM_NAME].each do |filter|
          self.more_filters << AdditionalFilter.new(filter, self)
        end if !@params.blank? && @params[AdditionalFilter::FORM_NAME] && !@params[AdditionalFilter::FORM_NAME].blank?
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

        self.more_filters.each do |m_filter|
          unless m_filter.mongo_conditions.blank?
            cond = m_filter.mongo_conditions
            if @mongo_conditions[m_filter.key] && @mongo_conditions[m_filter.key].is_a?(Hash)
              @mongo_conditions[m_filter.key].merge!(cond[m_filter.key])
            else
             @mongo_conditions.merge!(m_filter.mongo_conditions)
            end
          end
        end unless self.more_filters.blank?
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