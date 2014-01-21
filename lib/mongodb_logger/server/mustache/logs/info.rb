require 'mongodb_logger/server/mustache_helpers'
module MongodbLogger
  class Server
    module Views
      module Logs
        class Info < Mustache
          def log
            #MongodbLogger::MustacheHelpersObj.log_data(@log)
            @log
          end
        end
      end
    end
  end
end