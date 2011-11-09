require 'fileutils'

Before do
  @terminal = Terminal.new
end

After do |story|
  if story.failed?
    # puts @terminal.output
  end
end

class Terminal
  attr_reader :output, :status
  attr_accessor :environment_variables, :invoke_heroku_rake_tasks_locally

  def initialize
    @cwd = FileUtils.pwd
    @output = ""
    @status = 0
    @logger = Logger.new(File.join(TEMP_DIR, 'terminal.log'))
  end

  def cd(directory)
    @cwd = directory
  end

  def run(command)
    output << "#{command}\n"
    FileUtils.cd(@cwd) do
      # The ; forces ruby to shell out so the env settings work right
      cmdline = "#{environment_settings} #{command} 2>&1 ; "
      logger.debug(cmdline)
      result = `#{cmdline}`
      logger.debug(result)
      output << result
    end
    @status = $?
  end

  def echo(string)
    logger.debug(string)
  end

  def build_and_install_gem(gemspec)
    pkg_dir = File.join(TEMP_DIR, 'pkg')
    FileUtils.mkdir_p(pkg_dir)
    output = `gem build #{gemspec} 2>&1`
    gem_file = Dir.glob("*.gem").first
    unless gem_file
      raise "Gem didn't build:\n#{output}"
    end
    target = File.join(pkg_dir, gem_file)
    FileUtils.mv(gem_file, target)
    install_gem(target)
  end

  def install_gem(gem)
    `gem install --no-ri --no-rdoc #{gem}`
  end

  def uninstall_gem(gem)
    `gem uninstall #{gem}`
  end

  attr_reader :logger
end