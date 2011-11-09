module RailsHelpers
  def rails_root_exists?
    File.exists?(environment_path)
  end
  
  def environment_path
    File.join(rails_root, 'config', 'environment.rb')
  end

  def application_controller_filename
    controller_filename = File.join(rails_root, 'app', 'controllers', "application_controller.rb")
  end

  def rails_root
    LOCAL_RAILS_ROOT
  end
  
  def rails30?
    rails_version =~ /^3.0/
  end
  
  def rails31?
    rails_version =~ /^3.1/
  end

  def rails_version
    @rails_version ||= begin
      rails_version = open(gemfile_path).read.match(/gem.*rails["'].*["'](.+)["']/)[1]
    end
  end

  def gemfile_path
    gemfile = File.join(rails_root, 'Gemfile')
  end

  def rakefile_path
    File.join(rails_root, 'Rakefile')
  end

  def bundle_gem(gem_name, version = nil)
    File.open(gemfile_path, 'a') do |file|
      gem = "gem '#{gem_name}'"
      gem += ", '#{version}'" if version
      file.puts(gem)
    end
  end
  
  def require_thread
    content = File.read(rakefile_path)
    content = "require 'thread'\n#{content}"
    File.open(rakefile_path, 'wb') { |file| file.write(content) }
  end
  
  def copy_tests
    FileUtils.cp(
      File.join(PROJECT_ROOT, 'test', 'rails', 'app', 'controllers', 'order_controller.rb'), 
      File.join(rails_root, 'app', 'controllers', 'order_controller.rb')
    )
    FileUtils.cp(
      File.join(PROJECT_ROOT, 'test', 'config', 'samples', 'database.yml'), 
      File.join(rails_root, 'config', 'database.yml')
    )
    FileUtils.cp_r(
      File.join(PROJECT_ROOT, 'test', 'rails', 'test'), 
      File.join(rails_root, 'test')
    )
  end
  
end

World(RailsHelpers)