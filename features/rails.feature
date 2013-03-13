Feature: Install the Gem in a Rails application

  Background:
    Given I successfully run `rails new rails_root -O --skip-gemfile`
    And I cd to "rails_root"

  Scenario: Use the gem without vendoring the gem in a Rails application
    When I run `mkdir -p public/assets`
    Then I run `rake mongodb_logger:assets:compile[public/assets]`
    And I should generate in assets folder mongodb_logger files