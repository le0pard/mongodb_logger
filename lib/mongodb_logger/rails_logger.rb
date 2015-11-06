module MongodbLogger
  if defined?(ActiveSupport::Logger)
    class RailsLogger < ActiveSupport::Logger; end
  else
    class RailsLogger < ActiveSupport::BufferedLogger; end
  end

  RailsLogger.class_eval do
    def initialize(path, level)
      super(path)
      @level = level
      @logdev.instance_variable_set(:@shift_age, nil)
      @logdev.instance_variable_set(:@shift_size, nil)
    end
  end
end
