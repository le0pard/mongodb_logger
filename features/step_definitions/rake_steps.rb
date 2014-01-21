Given /I've prepared the Rakefile/ do
  rakefile = File.join(PROJECT_ROOT, 'features', 'support', 'rake', 'Rakefile')
  target = File.join(TEMP_DIR, 'Rakefile')
  FileUtils.cp(rakefile, target)
end

When /I run rake with (.+)/ do |command|
  command = "rake #{command.gsub(' ','_')}"
  step %{I run `#{command}`}
end