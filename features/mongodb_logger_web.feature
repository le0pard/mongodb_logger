Feature: Install MongodbLogger Web and test it
  
  Scenario: Main page
    Given homepage
    Then I should see text that no logs in system
    
  Scenario: Tail logs button
    Given homepage
    And I should see start tail button
    When I click on start tail button
    Then I should see stop tails button
    And box with time of last log tail
    When I click on stop tail button
    Then I should see start tail button