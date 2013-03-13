require 'active_support/core_ext/string/inflections'

Then(/^I should generate in public\/assets files$/) do
  js_and_css = false
  Dir["#{LOCAL_RAILS_ROOT}/public/assets/*{.js,.css}"].each do |file|
    js_and_css = true unless /^mongodb_logger\-([0-9a-z]+)\.(js|css)$/.match(File.basename(file)).nil?
  end
  raise "mongodb_logger gem not installed in rails" if false == js_and_css
end

Then /^I should see the Rails version$/ do
  step %{I should see "Rails: #{ENV["RAILS_VERSION"]}"}
end