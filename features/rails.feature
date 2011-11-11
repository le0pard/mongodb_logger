Feature: Install the Gem in a Rails application and test it

  Background:
    Given I have built and installed the "mongodb_logger" gem

  Scenario: Use the gem without vendoring the gem in a Rails application
    When I generate a new Rails application
    And I configure my application to require the "mongodb_logger" gem
    And I setup mongodb_logger tests
    Then the tests should have run successfully