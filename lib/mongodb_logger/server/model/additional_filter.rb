require 'date'

module MongodbLogger
  module ServerModel
    class AdditionalFilter < Base

      FORM_NAME               = "more"
      FIXED_PARAMS_ON_FORM    = ['type', 'key', 'condition', 'value']

      VAR_TYPES               = ["integer", "string", "boolean", "date"]

      VAR_TYPE_CONDITIONS = [
        ["equals", "not equals", "regexes", "<", "<=", ">=", ">"],
        ["equals", "not equals", "regexes", "<", "<=", ">=", ">"],
        ["equals", "exists"],
        ["<", "<=", ">=", ">"]
      ]

      VAR_TYPE_VALUES = [
        [],
        [],
        ["true", "false"],
        []
      ]

      attr_reader :form_data, :filter_model

      def initialize(params, filter_model)
        @filter_model = filter_model
        @params = params
        FIXED_PARAMS_ON_FORM.each do |key|
          create_variable(key, nil)
        end
        set_params_to_methods
      end

      def self.get_type_index(type)
        type.nil? ? 0 : VAR_TYPES.index(type)
      end

      def get_type_index
        @type.nil? ? 0 : VAR_TYPES.index(@type)
      end

      def selected_values
        VAR_TYPE_VALUES[get_type_index]
      end

      def is_selected_values?
        !VAR_TYPE_VALUES[get_type_index].blank?
      end

      def form_name
        "#{filter_model.form_name}[#{FORM_NAME}][]"
      end

      def mongo_conditions
        data = Hash.new
        return data if self.key.blank?
        m_value = case self.type
        when "integer"
          self.value.to_i
        when "boolean"
          ("true" == self.value || "1" == self.value) ? true : false
        when "date"
          val_date = Date.parse(self.value) rescue nil
          Time.utc(val_date.year, val_date.month, val_date.day) unless val_date.nil?
        else
          self.value
        end
        data = case self.condition
        when "equals"
          {"#{self.key}" => m_value }
        when "not equals"
          {"#{self.key}" => { "$ne" => m_value }}
        when "exists"
          {"#{self.key}" => { "$exists" => m_value }}
        when "regexes"
          {"#{self.key}" => { "$regex" => m_value, "$options" => 'i' }}
        when "<"
          {"#{self.key}" => { "$lt" => m_value }}
        when "<="
          {"#{self.key}" => { "$lte" => m_value }}
        when ">"
          {"#{self.key}" => { "$gt" => m_value }}
        when ">="
          {"#{self.key}" => { "$gte" => m_value }}
        else
          Hash.new
        end
        data
      end

    end
  end
end