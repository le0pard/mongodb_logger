require 'mongodb_logger/server/helpers/sprokets'
require 'mongodb_logger/utils/migrate'

namespace :mongodb_logger do
  desc 'copy data from mongodb collection to another'
  task :migrate => :environment do |t, args|
    MongodbLogger::Utils::Migrate.new.run
    puts "Operation finished"
  end

  namespace :assets do

    desc 'compile all assets'
    task :compile, [:output_dir] => [:compile_js, :compile_css, :compile_img]

    desc 'compile javascript assets'
    task :compile_js, [:output_dir] => :environment do |t, args|
      return (raise "Specify output dir for assets") if args.output_dir.nil?
      sprockets   = MongodbLogger::Assets.instance
      asset_name  = 'mongodb_logger.js'
      asset       = sprockets[asset_name]
      asset.write_to(File.join(args.output_dir, sprockets.find_asset(asset_name).digest_path))
      puts "successfully compiled js assets"
    end

    desc 'compile css assets'
    task :compile_css, [:output_dir] => :environment do |t, args|
      return (raise "Specify output dir for assets") if args.output_dir.nil?
      sprockets   = MongodbLogger::Assets.instance
      asset_name  = 'mongodb_logger.css'
      asset       = sprockets[asset_name]
      asset.write_to(File.join(args.output_dir, sprockets.find_asset(asset_name).digest_path))
      puts "successfully compiled css assets"
    end

    desc 'compile images assets'
    task :compile_img, [:output_dir] => :environment do |t, args|
      return (raise "Specify output dir for assets") if args.output_dir.nil?
      sprockets   = MongodbLogger::Assets.instance
      asset_names  = ['logo.png', 'spinner.gif']
      asset_names.each do |asset_name|
        asset       = sprockets[asset_name]
        asset.write_to(File.join(args.output_dir, sprockets.find_asset(asset_name).digest_path))
      end
      puts "successfully compiled images assets"
    end
  end
end