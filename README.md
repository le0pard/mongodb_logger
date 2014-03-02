# MongodbLogger
[![Build Status](https://travis-ci.org/le0pard/mongodb_logger.png)](https://travis-ci.org/le0pard/mongodb_logger)
[![Code Climate](https://codeclimate.com/github/le0pard/mongodb_logger.png)](https://codeclimate.com/github/le0pard/mongodb_logger)

MongodbLogger is a alternative logger for Rails or Rack based app, which log all requests of you application into MongoDB database.
It:

* simple to integrate into existing Rails application;
* allow to store all logs from web cluster into one scalable storage - MongoDB;
* flexible schema of MongoDB allow to store and search any information from logs;
* web panel allow filter logs, build graphs using MapReduce by information from logs;

## Rails support

Please note the latest version is compatible with rails 3.1.x or newer.

For rails 3.0.x latest version 0.2.8.

Doesn't support the Rails version below 3.

## Installation

1. Add the following to your Gemfile then refresh your dependencies by executing "bundle install" (or just simple "bundle"):

        gem "mongodb_logger"

1. Add adapter in Gemfile. Supported mongo and moped (mongoid). For example:

        gem "mongo"
        gem "bson_ext"

  or

        gem "moped"

1. Add the following line to your ApplicationController:

        include MongodbLogger::Base

1. For use with Heroku you need to prevent the rails\_log\_stdout plugin from being added by Heroku for rails 3:

        mkdir vendor/plugins/rails_log_stdout
        touch vendor/plugins/rails_log_stdout/.gitkeep

   For Rails 4 just remove from Gemfile "rails_12factor" gem.

1. Add MongodbLogger settings to database.yml for each environment in which you want to use the MongodbLogger. The MongodbLogger will also
   look for a separate mongodb\_logger.yml or mongoid.yml (if you are using mongoid) before looking in database.yml.
   In the mongodb\_logger.yml and mongoid.yml case, the settings should be defined without the 'mongodb\_logger' subkey.

   database.yml:

        development:
          adapter: postgresql
          database: my_app_development
          username: postgres
          mongodb_logger:
            database: my_app               # required (the only required setting)
            capsize: <%= 10.megabytes %>   # default: 250MB
            host: localhost                # default: localhost
            port: 27017                    # default: 27017
            replica_set: true              # default: false - Adds retries for ConnectionFailure during voting for replica set master
            write_options:                 # default: {w: 0, wtimeout: 200} - write options for inserts (w - wait for insert to propagate to "w" numbers of nodes)
              w: 0
              wtimeout: 200
            application_name: my_app       # default: Rails.application
            disable_file_logging: false    # default: false - disable logging into filesystem (only in MongoDB)
            collection: some_name          # default: Rails.env + "_log" - name of MongoDB collection

   mongodb\_logger.yml:

        development:
          database: my_app
          capsize: <%= 10.megabytes %>
          host: localhost
          port: 27017
          replica_set: true

   Also you can use "url" parameter for setup connection to mongodb:

        development:
          url: mongodb://localhost:27017/my_app
          capsize: <%= 10.megabytes %>


1. For using with MongoDB Replica Set (more info you can read by this link [http://www.mongodb.org/display/DOCS/Replica+Sets](http://www.mongodb.org/display/DOCS/Replica+Sets)). In config set list of [host, port] in key "hosts":

        development:
          database: my_app
          capsize: <%= 10.megabytes %>
          host: localhost
          port: 27017
          hosts:
            - - 127.0.0.1
              - 27018
            - - 127.0.0.1
              - 27019

1. For assets pipeline you can generate all js/css file into folder by rake task:

        rake mongodb_logger:assets:compile[public/assets]

## Assets pipeline

For capistrano possible compile assets by receipt. Add this to config/deploy.rb:

    require 'mongodb_logger/capistrano'
    set :mongodb_logger_assets_dir, "public/assets" # where to put mongodb assets
    after 'deploy:update_code', 'mongodb_logger:precompile'

Also you can serve assets from rails app. You need just mount it separately:

    mount MongodbLogger::Server.new, :at => "/mongodb", :as => :mongodb
    mount MongodbLogger::Assets.instance, :at => "/mongodb/assets", :as => :mongodb_assets # assets


## Usage

After success instalation of gem, a new MongoDB document (record) will be created for each request on your application,
by default will record the following information: Runtime, IP Address, Request Time, Controller, Method,
Action, Params, Application Name and All messages sent to the logger. The structure of the MongoDB document looks like this:

    {
      'action'           : action_name,
      'application_name' : application_name (rails root),
      'controller'       : controller_name,
      'ip'               : ip_address,
      'messages'         : {
                             'info'  : [ ],
                             'debug' : [ ],
                             'error' : [ ],
                             'warn'  : [ ],
                             'fatal' : [ ]
                           },
      'params'           : { },
      'path'             : path,
      'request_time'     : date_of_request,
      'runtime'          : elapsed_execution_time_in_milliseconds,
      'url'              : full_url,
      'method'           : request method (GET, POST, OPTIONS),
      'session'          : information from session,
      'is_exception'     : true only for exceptions (in other cases this field miss)
    }

Beyond that, if you want to add extra information to the base of the document (let's say something like user\_id on every request that it's available),
you can just call the Rails.logger.add\_metadata method on your logger like so (for example from a before\_filter):

    # make sure we're using the MongodbLogger in this environment
    Rails.logger.add_metadata(user_id: @current_user.id) if Rails.logger.respond_to?(:add_metadata)

## Callback on exceptions

For send email or do something on exception you can add callback:

    MongodbLogger::Base.configure do |config|
      config.on_log_exception do |mongo_record|
        # do something with this data, for example - send email (better - by background job)
      end
    end

In this callback send record without "\_id", because logger not wait for insert response from MongoDB.

## Disable mongodb_logger

To disable MongodbLogger you can use option disable. But this should be set before rails load (for example in Rails app the top of "config/application.rb"):

    MongodbLogger::Base.configure do |config|
      config.disable = true
    end

or

     MongodbLogger::Base.disable = true

## Migrate to another size of capped collection

If you need change capper collection size, you should change the "capsize" key in mongodb\_config and run this task for migration:

    rake mongodb_logger:migrate

## Rack Middleware

If you want use MongodbLogger in Rack app which is mounted to your Rails app, you can try to use rack middleware:

    use MongodbLogger::RackMiddleware

## Rails::Engine

If you want use MongodbLogger with some of Rails::Engine, you can do this (example for Spree):

    Spree::BaseController.send :include, MongodbLogger::Base
    Spree::Admin::BaseController.send :include, MongodbLogger::Base # for admin

## The Front End

To setup web interface in you Rails application, first of all create autoload file in you Rails application

File: you\_rails\_app/config/initializers/mongodb\_logger.rb (example)

    require 'mongodb_logger/server' # required
    # this secure you web interface by basic auth, but you can skip this, if you no need this
    MongodbLogger::Server.use Rack::Auth::Basic do |username, password|
        [username, password] == ['admin', 'password']
    end

and just mount MongodbLogger::Server in rails routes:

File: you\_rails\_app/config/routes.rb

    mount MongodbLogger::Server.new, :at => "/mongodb"

Now you can see web interface by url "http://localhost:3000/mongodb"

If you've installed MongodbLogger as a gem and want running the front end without Rails application, you can do it by this command:

    mongodb_logger_web config.yml

where config.yml is config, similar to config of Rails apps, but without Rails.env. Example:

    database: app_logs_dev
    host: localhost
    port: 27017
    collection: development_log # set for see development logs

parameter "collection" should be set, if your set custom for your Rails application or start this front end not for production
enviroment (by default taken "production\_log" collection, in Rails application gem generate "#{Rails.env}\_log" collection,
if it is not defined in config).

It's a thin layer around rackup so it's configurable as well:

    mongodb_logger_web config.yml -p 8282

###  Passenger, Unicorn, Thin, etc.

Using Passenger, Unicorn, Thin, etc? MongodbLogger ships with a `config.ru` you can use. See  guide:

* Passenger Apache: <http://www.modrails.com/documentation/Users%20guide%20Apache.html#_deploying_a_rack_based_ruby_application>
* Passenger Nginx: <http://www.modrails.com/documentation/Users%20guide%20Nginx.html#deploying_a_rack_app>
* Unicorn: <http://unicorn.bogomips.org>
* Thin: <http://code.macournoyer.com/thin/usage>

Don't forget setup MONGODBLOGGERCONFIG env variable, which provide information about MongodbLogger config. Example starting with unicorn:

    MONGODBLOGGERCONFIG=examples/server_config.yml unicorn

##  Demo Application with MongodbLogger

Demo: [http://demo-mongodb-logger.catware.org/](http://demo-mongodb-logger.catware.org/)

Demo Sources: [https://github.com/le0pard/mongodb_logger_example_heroku](https://github.com/le0pard/mongodb_logger_example_heroku)


## Querying via the Rails console

  And now, for a couple quick examples on getting ahold of this log data...
  First, here's how to get a handle on the MongoDB from within a Rails console:

    >> db = Rails.logger.mongo_adapter.connection
    => #<Mongo::DB:0x007fdc7c65adc8 @name="monkey_logs_dev" ... >
    >> collection = Rails.logger.mongo_adapter.collection
    => #<Mongo::Collection:0x007fdc7a4d12b0 @name="development_log" .. >

  Once you've got the collection, you can find all requests for a specific user (with id):

    >> cursor = collection.find(:user_id => '12355')
    => #<Mongo::Cursor:0x1031a3e30 ... >
    >> cursor.count
    => 5

  Find all requests that took more that one second to complete:

    >> collection.find({:runtime => {'$gt' => 1000}}).count
    => 3

  Find all order#show requests with a particular order id (id=order\_id):

    >> collection.find({"controller" => "order", "action"=> "show", "params.id" => order_id})

  Find all requests with an exception that contains "RoutingError" in the message or stack trace:

    >> collection.find({"messages.error" => /RoutingError/})

  Find all requests with errors:

    >> collection.find({"is_exception" => true})

  Find all requests with a request\_date greater than '11/18/2010 22:59:52 GMT'

    >> collection.find({:request_time => {'$gt' => Time.utc(2010, 11, 18, 22, 59, 52)}})


Copyright (c) 2009-2014 Phil Burrows, CustomInk (based on https://github.com/customink/central_logger) and Leopard released under the MIT license
