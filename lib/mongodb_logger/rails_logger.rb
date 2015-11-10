module MongodbLogger
  if defined?(ActiveSupport::Logger)
    class RailsLogger < ActiveSupport::Logger
      def initialize(path, level)
        super(path)
        @level = level
        @logdev.instance_variable_set(:@shift_age, nil)
        @logdev.instance_variable_set(:@shift_size, nil)
      end
    end
  else
    class RailsLogger < ActiveSupport::BufferedLogger; end
  end
end
