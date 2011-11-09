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
  
end

World(RailsHelpers)