module MongodbLogger
  module ServerModel
    class AdditionalFilter
    
      module VAR_TYPE
        STR     = 1
        INT     = 2
        DATE    = 3
      end
      
      module VAR_CONDITIONS
        DEFAULT       = ["equals", "not equals", "exists", "regexes"]
        STR           = DEFAULT.dup
        INT           = DEFAULT.dup + ["<", "<=", "=>", ">"]
        DATE          = DEFAULT.dup + ["<", "<=", "=>", ">"]
      end
      
      def self.get_by_val_type(type)
        case type
          when VAR_TYPE::STR then 
            VAR_CONDITIONS::STR
          when VAR_TYPE::INT then 
            VAR_CONDITIONS::INT
          when VAR_TYPE::DATE then 
            VAR_CONDITIONS::DATE
          else
            VAR_CONDITIONS::DEFAULT
        end
      end
    
    end
  end
end