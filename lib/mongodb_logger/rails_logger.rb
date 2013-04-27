require 'active_support/core_ext'

module MongodbLogger
  if defined?(ActiveSupport::Logger)
    class RailsLogger < ActiveSupport::Logger; end
  else
    require 'active_support/core_ext/logger'
    class RailsLogger < ActiveSupport::BufferedLogger; end
  end
end
