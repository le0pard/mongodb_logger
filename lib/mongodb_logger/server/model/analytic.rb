module MongodbLogger
  module ServerModel
    class Analytic
      
      FIXED_PARAMS_ON_FORM = ['type']
      ANALYTIC_TYPES = [[0, "Count of requests"], [1, "Count of errors"]]
      attr_reader :params, :collection
      FORM_NAME = "analytic"
      
      
      def initialize(collection, params)
        FIXED_PARAMS_ON_FORM.each do |key|
          create_variable(key, nil)
        end
        @collection = collection
        @params = params
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
        FORM_NAME
      end
      
      def count_of_requests(conditions, is_errors = false)
        map = "function() { var key = {year: this.request_time.getFullYear(),month: this.request_time.getMonth(), day: this.request_time.getDate()}; emit(key, {count: 1});}"
        reduce_count = "function(key, values) { var sum = 0; values.forEach(function(f) { sum += f.count; }); return {count: sum};}"
        conditions = conditions.merge({:is_exception => true}) if is_errors
        @collection.map_reduce(map, reduce_count, {:out => {:replace => "mongodb_logger_count_of_requests"}, :query => conditions, :sort => ['$natural', -1]})
      end
      
      def get_collection
        # temporary
        today_date = Date.today
        conditions = { :request_time => {'$gte' => Time.utc(today_date.year, today_date.month, 1), "$lt" => Time.utc(today_date.year, today_date.month, today_date.day)}}
        
        mapreduce_collection = case self.type.to_i
        when 0
          count_of_requests(conditions)
        when 1
          count_of_requests(conditions, true)
        else
          count_of_requests(conditions)
        end
        
        mapreduce_collection
      end
      
    end
  end
end