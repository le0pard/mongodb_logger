Feature: Install MongodbLogger Web and test it

  Scenario: Main page
    Given homepage
    Then I should see text that no logs in system

  Scenario: Filter logs button
    Given homepage
    And I should see show filter button
    When I click on show filter button
    Then I should see hide filter button
    When I click on hide filter button
    Then I should see show filter button