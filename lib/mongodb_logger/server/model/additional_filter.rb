module MongodbLogger
  module ServerModel
    class AdditionalFilter
      
      FORM_NAME               = "more"
      FIXED_PARAMS_ON_FORM    = ['type', 'key', 'condition', 'value']
      
      VAR_TYPES               = ["int", "str", "bool"]
      DEFAULT_CONDITIONS      = ["equals", "not equals", "exists", "regexes", "<", "<=", ">=", ">"]
      
      attr_reader :form_data, :filter_model
      
      def initialize(params, filter_model)
        @filter_model = filter_model
        @params = params
        FIXED_PARAMS_ON_FORM.each do |key|
          create_variable(key, nil)
        end
        @params.each do |k,v|
          self.send("#{k}=", v) if self.respond_to?(k) && v && !v.blank?
        end unless @params.blank?
      end
      
      def create_variable(k, v)
        self.instance_variable_set("@#{k}", v)  ##  create instance variable
        self.class.send(:define_method, k, proc{self.instance_variable_get("@#{k}")})  ## method to return instance variable
        self.class.send(:define_method, "#{k}=", proc{|v| self.instance_variable_set("@#{k}", v)})  ## method to set instance variable
      end
      
      def form_name
        "#{filter_model.form_name}[#{FORM_NAME}][]"
      end
    
    end
  end
end