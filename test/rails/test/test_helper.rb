ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  def common_setup
    @con = @mongodb_logger.mongo_connection
    @collection = @con[@mongodb_logger.mongo_collection_name]
  end
end
