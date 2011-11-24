module MongodbLogger
  module ServerModel
    class AdditionalFilter
      
      VAR_TYPES               = [:str, :int, :date]
      DEFAULT_CONDITIONS      = ["equals", "not equals", "exists", "regexes"]
      
      attr_reader :form_data
      
      def initialize(form_data)
        @form_data = form_data
      end
    
    end
  end
end