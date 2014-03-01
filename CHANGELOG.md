## master


## 0.6.3

* Allows a user to override the request_ip method (#56)
* Better support Sinatra apps (#60)
* Support moped 2.0.0.beta8
* Support Rails 4.1.0.rc1
* Removed unused actionpack

## 0.6.2

* Disable gem by option disable = false.

## 0.6.1

* Fix problem with store sessions

## 0.6.0

* Support Rails 4
* config as hash with indifferent access

## 0.5.2

* Use new mongo API
* Support ssl connection
* Fix js hotkeys on filters
* Added support of Rails 3.2 Tagged Logging [#54]

## v0.5.1

* Fixed params info in info box

## v0.5.0

* Moved to new rspec and cucumber testing, fixed testing in travis
* Added migration task for changed capped collection size ([#49](https://github.com/le0pard/mongodb_logger/issues/49))
* Moved some part of web ui on mustache templates (now no need load info from server for right info tab)
* Change dependency from json to multi\_json gem
* Fix js problems on web page
* Cleanup and DRY the code

## v0.4.2

* Fix problem with session keys (keys with dots is invalid for BSON)

## v0.4.1

* One gem for jruby and MRI

## v0.4.0

* Support adapters: mongo and moped
* Change safe\_insert option to write\_options
* Changed MapReduce graphs to Rickshaw
* Huge rewrites of code

## v0.3.3

* Mount assets separately or compile it by rake task
* Capistrano recipe for compiling assets

## v0.3.2

* Initialize a connection to MongoDB using the MongoDB URI spec
* Fix logger.info/warn/error for Rails 3.2.x

## v0.3.1

* Fix broken images in if using assets pipeline

## v0.3.0

* Added assets pipeline support

## v0.2.8

* Added callback on exception
* Delete deprecate warnings

## v0.2.7

* Fixed error trace for ruby 1.9.2
* Update gems dependency

## v0.2.6

* Replica Set set in config by key 'hosts'
* Adding jruby support

## v0.2.5

* Build graphs for analytics page
* Fix month for analytics

## v0.2.4

* Move on logs list by using arrows on keybords

## v0.2.3

* Fix storage log with attachments (save it for search by "original\_filename" and "content\_type")
* Fix tests for CI

## v0.2.2

* Fix set custom collection in config and add tests on it

## v0.2.1

* Add show on 'more info' page meta data from log

## v0.2.0

* Public release
