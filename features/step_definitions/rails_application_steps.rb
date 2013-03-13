require 'active_support/core_ext/string/inflections'

When /I run `(.+)`/ do |command|
  `#{command}`
end

When /I successfully run `(.+)`/ do |command|
  step %{I run `#{command}`}
end