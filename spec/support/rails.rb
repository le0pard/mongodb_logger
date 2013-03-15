module MongodbLogger
  class Application
  end
end

class Rails
  module VERSION
    MAJOR = 3
  end

  def self.env
    ActiveSupport::StringInquirer.new("test")
  end

  def self.root
    Pathname.new(File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "tmp")))
  end

  def self.application
    MongodbLogger::Application.new
  end

  def self.logger
    MongodbLogger::Logger.new
  end
end

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