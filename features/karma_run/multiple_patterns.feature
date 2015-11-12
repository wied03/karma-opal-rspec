Feature: Multiple patterns

  Background:
    Given the 'multiplePatterns.js' Karma config file

  Scenario: Basic
    Given the mult_patterns tests
    When I run the Karma test
    Then the test passes with JSON results:
    """
    {
        "something nested": {
            "should eq 42": "PASSED"
        },
        "other nested": {
            "should eq 42": "PASSED"
        }
    }
    """
