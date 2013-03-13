Feature: Install the Gem in a Rails application

  Background:
    Given I successfully run `rails new rails_root -O --skip-gemfile`
    And I cd to "rails_root"

  Scenario: Use the gem without vendoring the gem in a Rails application
    When I run `rake mongodb_logger:assets:compile[public/assets]`
    Then I should generate in public/assets files
    And I should see the Rails version