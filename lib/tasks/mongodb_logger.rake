require 'mongodb_logger/server/sprokets'
namespace :mongodb_logger do
  namespace :assets do
    desc 'compile assets'
    task :compile => [:compile_js, :compile_css] do
    end

    desc 'compile javascript assets'
    task :compile_js, [:output_dir] => :environment do |t, args|
      return (raise "Specify output dir for assets") if args.output_dir.nil?
      sprockets = MongodbLogger::Assets.instance
      asset     = sprockets['mongodb_logger.js']
      asset.write_to(output_dir)
      puts "successfully compiled js assets"
    end

    desc 'compile css assets'
    task :compile_css, [:output_dir] => :environment do |t, args|
      return (raise "Specify output dir for assets") if args.output_dir.nil?
      sprockets = MongodbLogger::Assets.instance
      asset     = sprockets['mongodb_logger.css']
      asset.write_to(output_dir)
      puts "successfully compiled css assets"
    end
  end
end