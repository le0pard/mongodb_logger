Feature: Install the Gem in a Rails application

  Background:
    Given I successfully run `rails new rails_root -O --skip-gemfile`
    And I cd to "rails_root"

  Scenario: Use the gem without vendoring the gem in a Rails application
    When I run `mkdir -p public/assets`
    Then I run `rake mongodb_logger:assets:compile[public/assets]`
    And I should generate in assets folder mongodb_logger files

  Scenario: Configure the rspec in rails app and test it
    When I have set up tests controllers
    Then I route "tests" to resources
    Then I run `rake routes`
    And I should see "/tests(.:format)"
    When I have copy tests_controller_spec
    Then I run `rspec spec`
    Then I should see ", 0 failure"
    And I should see like this /((?=\d*[1-9])\d+) examples, 0 failure/