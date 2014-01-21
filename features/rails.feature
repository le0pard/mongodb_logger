Feature: Install the Gem in a Rails application

  Background:
    Given I successfully run `rails new rails_root -O --skip-gemfile`
    And I cd to "rails_root"
    When I have set up tests controllers
    Then I route "tests" to resources
    And I run `rake routes`
    When I should see "/tests(.:format)"
    And I have copy tests_controller_spec

  Scenario: Use the gem without vendoring the gem in a Rails application
    When I run `mkdir -p public/assets`
    Then I run `rake mongodb_logger:assets:compile[public/assets]`
    And I should generate in assets folder mongodb_logger files

  Scenario: Run rspec in rails app
    When I run `rspec spec`
    And I should see like this /((?=\d*[1-9])\d+) examples, 0 failure/

  Scenario: Run rake command in rails app
    When I run `rake mongodb_logger:migrate`
    Then the exit status should be 0
    And I should see "Operation finished"