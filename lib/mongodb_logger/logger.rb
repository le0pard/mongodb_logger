require 'erb'
require 'uri'
require 'active_support'
require 'active_support/core_ext'
require 'active_support/core_ext/logger'
require 'action_dispatch/http/upload'
require 'mongodb_logger/adapters'
require 'mongodb_logger/replica_set_helper'

module MongodbLogger
  class Logger < ActiveSupport::BufferedLogger
    include ReplicaSetHelper

    DEFAULT_COLLECTION_SIZE = 250.megabytes
    # Looks for configuration files in this order
    CONFIGURATION_FILES = ["mongodb_logger.yml", "mongoid.yml", "database.yml"]
    LOG_LEVEL_SYM = [:debug, :info, :warn, :error, :fatal, :unknown]

    ADAPTERS = [
      ["mongo", Adapers::Mongo],
      ["moped", Adapers::Moped]
    ]

    attr_reader :db_configuration, :mongo_adapter

    def initialize(options = {})
      path = options[:path] || File.join(Rails.root, "log/#{Rails.env}.log")
      @level = options[:level] || DEBUG
      internal_initialize
    rescue => e
      # should use a config block for this
      Rails.env.production? ? (raise e) : (puts "MongodbLogger WARNING: Using BufferedLogger due to exception: #{e.message}")
    ensure
      if disable_file_logging?
        @log            = ::Logger.new(STDOUT)
        @log.level      = @level
      else
        super(path, @level)
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
      if @level && @level <= severity && message.present? && @mongo_record.present?
        # do not modify the original message used by the buffered logger
        msg = logging_colorized? ? message.to_s.gsub(/(\e(\[([\d;]*[mz]?))?)?/, '').strip : message
        @mongo_record[:messages][LOG_LEVEL_SYM[severity]] << msg
      end
      # may modify the original message
      disable_file_logging? ? message : (@level ? super : message)
    end

    def mongoize(options = {})
      @mongo_record = options.merge({
        :messages => Hash.new { |hash, key| hash[key] = Array.new },
        :request_time => Time.now.getutc,
        :application_name => @db_configuration['application_name']
      })

      runtime = Benchmark.measure{ yield }.real if block_given?
    rescue Exception => e
      add(3, e.message.to_s + "\n" + e.backtrace.join("\n"))
      # log exceptions
      @mongo_record[:is_exception] = true
      # Reraise the exception for anyone else who cares
      raise e
    ensure
      # In case of exception, make sure runtime is set
      @mongo_record[:runtime] = ((runtime ||= 0) * 1000).ceil
      # error callback
      Base.on_log_exception(@mongo_record) if @mongo_record[:is_exception]
      begin
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
    end

    private

      def internal_initialize
        configure
        connect
        check_for_collection
      end

      def disable_file_logging?
        @db_configuration.fetch('disable_file_logging', false)
      end

      def configure
        default_capsize = DEFAULT_COLLECTION_SIZE
        @db_configuration = {
          'host' => 'localhost',
          'port' => 27017,
          'capsize' => default_capsize,
          'ssl' => false}.merge(resolve_config)
        @db_configuration['collection'] ||= defined?(Rails) ? "#{Rails.env}_log" : "production_log"
        @db_configuration['application_name'] ||= resolve_application_name
        @db_configuration['write_options'] ||= { w: 0, wtimeout: 200 }

        @insert_block = @db_configuration.has_key?('replica_set') && @db_configuration['replica_set'] ?
          lambda { rescue_connection_failure{ insert_log_record(@db_configuration['write_options']) } } :
          lambda { insert_log_record(@db_configuration['write_options']) }
      end

      def resolve_application_name
        Rails.application.class.to_s.split("::").first if defined?(Rails)
      end

      def resolve_config
        config = {}
        CONFIGURATION_FILES.each do |filename|
          config_file = Rails.root.join("config", filename)
          if config_file.file?
            config = YAML.load(ERB.new(config_file.read).result)[Rails.env]
            config = config['mongodb_logger'] if config && config.has_key?('mongodb_logger')
            break unless config.blank?
          end
        end
        config
      end

      def find_adapter
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
            hvalues = {
              original_filename: data.original_filename,
              content_type: data.content_type
            }
          else
            data.inspect
        end
      end

  end
end
