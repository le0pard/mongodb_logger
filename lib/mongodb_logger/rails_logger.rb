module MongodbLogger
  if defined?(ActiveSupport::Logger)
    class RailsLogger < ActiveSupport::Logger; end
  else
    class RailsLogger < ActiveSupport::BufferedLogger; end
  end
end
