module MongodbLogger
  module ServerModel
    class Analytic < Base

      FIXED_PARAMS_ON_FORM = ['type', 'unit', 'start_date', 'end_date']
      ANALYTIC_TYPES = [[0, "Count of requests"], [1, "Count of errors"]]
      ANALYTIC_UNITS = [[0, "Month"], [1, "Day"], [2, "Hour"]]

      attr_reader :params, :mongo_adapter
      FORM_NAME = "analytic"

      def initialize(mongo_adapter, params)
        FIXED_PARAMS_ON_FORM.each do |key|
          create_variable(key, nil)
        end
        @mongo_adapter = mongo_adapter
        @params = params
        set_params_to_methods
        # def values
        self.start_date ||= Time.now.strftime('%Y-%m-%d')
        self.end_date ||= Time.now.strftime('%Y-%m-%d')
      end

      def form_name
        FORM_NAME
      end

      def calculate_default_map_reduce(params = {})
        addinional_params = case self.unit.to_i
          when 1
            "day: this.request_time.getDate()"
          when 2
            "day: this.request_time.getDate(), hour: this.request_time.getHours() + 1"
          else
            ""
        end
        map = <<EOF
function() {
  var key = {
    year: this.request_time.getFullYear(),
    month: this.request_time.getMonth() + 1,
    #{addinional_params}
  };
  emit(key, {count: 1});
}
EOF
        reduce = <<EOF
function(key, values) {
  var sum = 0;
  values.forEach(function(f) {
    sum += f.count;
  });
  return {count: sum};
}
EOF
        case self.type.to_i
          when 1
            params[:conditions].merge!({ is_exception: true })
          else
            # nothing
        end

        @mongo_adapter.calculate_mapreduce(map, reduce, { conditions: params[:conditions] })
      end

      def get_data
        m_start= Date.parse(self.start_date) rescue Date.today
        m_end = Date.parse(self.end_date) rescue Date.today

        conditions = { request_time: {
          '$gte' => Time.utc(m_start.year, m_start.month, m_start.day, 0, 0, 0),
          '$lte' => Time.utc(m_end.year, m_end.month, m_end.day, 23, 59, 59)
        }}

        all_data = calculate_default_map_reduce(
          conditions: conditions
        )

        {
          data: (all_data && all_data.first ? all_data.first.last : []),
          headers: {
            key: ["year", "month", "day", "hour"],
            value: ["count"]
          },
          unit: self.unit
        }
      end

    end
  end
end