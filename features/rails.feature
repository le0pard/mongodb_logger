Feature: Install the Gem in a Rails application

  Background:
    Given I successfully run `rails new rails_root -O --skip-gemfile`
    And I cd to "rails_root"

  Scenario: Use the gem without vendoring the gem in a Rails application
    When I run `rails generate airbrake -k myapikey`
    Then I should receive a Airbrake notification
    And I should see the Rails version