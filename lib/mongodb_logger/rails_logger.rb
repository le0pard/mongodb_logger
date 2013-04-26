require 'active_support/core_ext/logger' unless defined?(ActiveSupport::Logger)
module MongodbLogger
  class RailsLogger < (defined?(ActiveSupport::Logger) ? ActiveSupport::Logger : ActiveSupport::BufferedLogger); end
end