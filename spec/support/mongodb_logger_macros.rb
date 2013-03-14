require File.expand_path(File.join(File.dirname(__FILE__), "rails.rb"))

module MongodbLogger::SpecMacros
  def should_contain_one_log_record
    it "contain a log record" do
      @mongo_adapter.collection.find.count.should == 1
    end
  end

  def should_use_database_name_in_config
    it "use the database name in the config file" do
      @mongodb_logger.db_configuration['database'].should == "system_log"
    end
  end
end