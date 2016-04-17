Feature: error handling

  Scenario: Missing require on JS side
    Given the 'singlePattern.js' Karma config file
    And the missing_require tests
    When I run the Karma test
    Then the test fails
    And the output should contain "Module build failed: Error: Cannot find file - missing_file"

  Scenario: Invalid MRI require causes error in webpack loader
    Given the 'invalidRackConfig.js' Karma config file
    And the simple tests
    When I run the Karma test
    Then the test fails
    And the output should contain "cannot load such file -- foobar"
