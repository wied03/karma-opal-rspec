Feature: Source maps

  Background:
    Given the 'sourceMaps.js' Karma config file

  Scenario: Nothing breaks
    Given the simple tests
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
