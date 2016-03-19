Feature: error handling

  Scenario: Missing require on JS side
    Given the 'singlePattern.js' Karma config file
    And the missing_require tests
    When I run the Karma test
    Then the test fails
    And the output should contain "because: Sprockets::FileNotFound - couldn't find file 'missing_file' with type 'application/javascript"

  Scenario: Invalid MRI require causes Rack crash
    Given the 'invalidRackConfig.js' Karma config file
    And the simple tests
    When I run the Karma test
    Then the test fails
    And the output should contain "Unable to update file metadata due to this error! Connection to Rack server refused, hit max limit of 50. There might have been an exception in Rack startup. Try running Karma with --log-level=debug"
