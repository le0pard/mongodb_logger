Feature: Install the Gem in a Rails application

  Background:
    Given I have built and installed the "mongodb_logger" gem

  Scenario: Use the gem without vendoring the gem in a Rails application
    When I generate a new Rails application