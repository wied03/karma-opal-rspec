Feature: error handling

  Scenario: Missing require on JS side
    Given the 'singlePattern.js' Karma config file
    And the missing_require tests
    When I run the Karma test
    Then the test fails
    And the output should contain "SprocketsAssetException: Unable to fetch asset metadata from Sprockets, error details: Sprockets::FileNotFound: couldn't find file 'missing_file' with type 'application/javascript'"

  Scenario: Invalid MRI require causes Rack crash
    Given the 'invalidRackConfig.js' Karma config file
    And the simple tests
    When I run the Karma test
    Then the test fails
    And the output should contain "SprocketsAssetException: Connection to Rack server refused, tried 20 times but hit max limit of 20."
