Feature: error handling

  Background:
      Given the 'singlePattern.js' Karma config file

  Scenario: Missing require
    Given the missing_require tests
    When I run the Karma test
    Then the test fails
    And the output should contain "SprocketsAssetException: Unable to fetch asset metadata from Sprockets, error details: Sprockets::FileNotFound: couldn't find file 'missing_file' with type 'application/javascript'"
