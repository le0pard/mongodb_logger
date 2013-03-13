require 'active_support/core_ext/string/inflections'

Then(/^I should generate in assets folder mongodb_logger files$/) do
  js_and_css = false
  Dir["#{LOCAL_RAILS_ROOT}/public/assets/*{.js,.css}"].each do |file|
    puts File.basename(file).inspect
    js_and_css = true unless /^mongodb_logger\-([0-9a-z]+)\.(js|css)$/.match(File.basename(file)).nil?
  end
  raise "mongodb_logger gem not installed in rails (assets not compiled)" if false == js_and_css
end

