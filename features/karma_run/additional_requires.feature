Feature: Additional requires

  Scenario: Additional requires specified
    Given the 'additionalRequires.js' Karma config file
    And the additional_requires tests
    When I run the Karma test
    Then the test passes with JSON results:
    """
    {
        "something nested": {
            "should eq 42": "PASSED"
        }
    }
    """
