module ActiveRecord
  class LogSubscriber
    def self.colorize_logging
      true
    end
  end

  class Base
    def self.colorize_logging
      true
    end
  end
end