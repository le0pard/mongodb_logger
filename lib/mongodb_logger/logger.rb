require 'erb'
require 'uri'
require 'active_support'
require 'active_support/core_ext'
require 'action_dispatch/http/upload'
require 'mongodb_logger/rails_logger'
require 'mongodb_logger/adapters'
require 'mongodb_logger/replica_set_helper'

module MongodbLogger
  class Logger < RailsLogger
    include ReplicaSetHelper

    DEFAULT_COLLECTION_SIZE = 250.megabytes
    # Looks for configuration files in this order
    CONFIGURATION_FILES = ["mongodb_logger.yml", "mongoid.yml", "database.yml"]
    LOG_LEVEL_SYM = [:debug, :info, :warn, :error, :fatal, :unknown]

    ADAPTERS = [
      ["mongo", Adapers::Mongo],
      ["moped", Adapers::Moped]
    ]

    attr_reader   :db_configuration, :mongo_adapter, :app_root, :app_env
    attr_writer   :excluded_from_log

    def initialize(path = nil, level = DEBUG)
      set_root_and_env
      begin
        path ||= File.join(app_root, "log/#{app_env}.log")
        @level = level
        internal_initialize
      rescue => e
        # should use a config block for this
        "production" == app_env ? (raise e) : (puts "MongodbLogger WARNING: Using Rails Logger due to exception: #{e.message}")
      ensure
        if disable_file_logging?
          @log            = ::Logger.new(STDOUT)
          @log.level      = @level
        else
          super(path, @level)
        end
      end
    end

    def add_metadata(options = {})
      options.each do |key, value|
        unless [:messages, :request_time, :ip, :runtime, :application_name, :is_exception, :params, :session, :method].include?(key.to_sym)
          @mongo_record[key] = value
        else
          raise ArgumentError, ":#{key} is a reserved key for the mongodb logger. Please choose a different key"
        end
      end if @mongo_record
    end

    def add(severity, message = nil, progname = nil, &block)
      $stdout.puts(message) if ENV['HEROKU_RACK'] # log in stdout on Heroku
      if @level && @level <= severity && (message.present? || progname.present?) && @mongo_record.present?
        add_log_message(severity, message, progname)
      end
      # may modify the original message
      disable_file_logging? ? message : (@level ? super : message)
    end

    def mongoize(options = {})
      @mongo_record = options.merge({
        messages: Hash.new { |hash, key| hash[key] = Array.new },
        request_time: Time.now.getutc,
        application_name: @db_configuration['application_name']
      })

      runtime = Benchmark.measure{ yield }.real if block_given?
    rescue Exception => e
      log_raised_error(e)
      # Reraise the exception for anyone else who cares
      raise e
    ensure
      # In case of exception, make sure runtime is set
      @mongo_record[:runtime] = ((runtime ||= 0) * 1000).ceil
      # error callback
      Base.on_log_exception(@mongo_record) if @mongo_record[:is_exception]
      ensure_write_to_mongodb
    end

    def excluded_from_log
      @excluded_from_log ||= nil
    end

    private

    def internal_initialize
      configure
      connect
      check_for_collection
    end

    def disable_file_logging?
      @db_configuration.fetch(:disable_file_logging, false)
    end

    def configure
      @db_configuration = {
        host: 'localhost',
        port: 27017,
        capsize: DEFAULT_COLLECTION_SIZE,
        ssl: false}.merge(resolve_config).with_indifferent_access
      @db_configuration[:collection] ||= "#{app_env}_log"
      @db_configuration[:application_name] ||= resolve_application_name
      @db_configuration[:write_options] ||= { w: 0, wtimeout: 200 }

      @insert_block = @db_configuration.has_key?(:replica_set) && @db_configuration[:replica_set] ?
        lambda { rescue_connection_failure{ insert_log_record(@db_configuration[:write_options]) } } :
        lambda { insert_log_record(@db_configuration[:write_options]) }
    end

    def resolve_application_name
      if defined?(Rails)
        Rails.application.class.to_s.split("::").first
      else
        "RackApp"
      end
    end

    def add_log_message(severity, message, progname)
      # do not modify the original message used by the buffered logger
      msg = (message ? message : progname)
      msg = logging_colorized? ? msg.to_s.gsub(/(\e(\[([\d;]*[mz]?))?)?/, '').strip : msg
      @mongo_record[:messages][LOG_LEVEL_SYM[severity]] << msg
    end

    def log_raised_error(e)
      add(3, "#{e.message}\n#{e.backtrace.join("\n")}")
      # log exceptions
      @mongo_record[:is_exception] = true
    end

    def ensure_write_to_mongodb
      @insert_block.call
    rescue
      begin
        # try to nice serialize record
        record_serializer @mongo_record, true
        @insert_block.call
      rescue
        # do extra work to inspect (and flatten)
        record_serializer @mongo_record, false
        @insert_block.call rescue nil
      end
    end

    def resolve_config
      config = {}
      CONFIGURATION_FILES.each do |filename|
        config = read_config_from_file(File.join(app_root, 'config', filename))
        break unless config.blank?
      end
      config
    end

    def read_config_from_file(config_file)
      if File.file? config_file
        config = YAML.load(ERB.new(File.new(config_file).read).result)[app_env]
        config = config['mongodb_logger'] if config && config.has_key?('mongodb_logger')
        return config unless config.blank?
      end
      return nil
    end

    def find_adapter
      return Adapers::Mongo if defined?(::Mongo)
      return Adapers::Moped if defined?(::Moped)

      ADAPTERS.each do |(library, adapter)|
        begin
          require library
          return adapter
        rescue LoadError
          next
        end
      end
      return nil
    end

    def connect
      adapter = find_adapter
      raise "!!! MongodbLogger not found supported adapter. Please, add mongo with bson_ext gems or moped gem into Gemfile !!!" if adapter.nil?
      @mongo_adapter ||= adapter.new(@db_configuration)
      @db_configuration = @mongo_adapter.configuration
    end

    def check_for_collection
      @mongo_adapter.check_for_collection
    end

    def insert_log_record(write_options)
      return if excluded_from_log && excluded_from_log.any? { |k, v| v.include?(@mongo_record[k]) }
      @mongo_adapter.insert_log_record(@mongo_record, write_options: write_options)
    end

    def logging_colorized?
      # Cache it since these ActiveRecord attributes are assigned after logger initialization occurs in Rails boot
      @colorized ||= Object.const_defined?(:ActiveRecord) && ActiveRecord::LogSubscriber.colorize_logging
    end

    # try to serialyze data by each key and found invalid object
    def record_serializer(rec, nice = true)
      [:messages, :params].each do |key|
        if msgs = rec[key]
          msgs.each do |i, j|
            msgs[i] = (true == nice ? nice_serialize_object(j) : j.inspect)
          end
        end
      end
    end

    def nice_serialize_object(data)
      case data
        when NilClass, String, Fixnum, Bignum, Float, TrueClass, FalseClass, Time, Regexp, Symbol
          data
        when Hash
          hvalues = Hash.new
          data.each{ |k,v| hvalues[k] = nice_serialize_object(v) }
          hvalues
        when Array
          data.map{ |v| nice_serialize_object(v) }
        when ActionDispatch::Http::UploadedFile, Rack::Test::UploadedFile # uploaded files
          {
            original_filename: data.original_filename,
            content_type: data.content_type
          }
        else
          data.inspect
      end
    end

    def set_root_and_env
      if defined? Rails
        @app_root, @app_env = Rails.root.to_s, Rails.env.to_s
      elsif defined? RACK_ROOT
        @app_root, @app_env = RACK_ROOT, (ENV['RACK_ENV'] || 'production')
      else
        @app_root, @app_env = File.dirname(__FILE__), 'production'
      end
    end

  end
end
