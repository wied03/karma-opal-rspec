Feature: Additional requires

  Scenario: Additional requires specified
    Given the 'additionalRequires.js' Karma config file
    And the additional_requires tests
    When I run the Karma test
    Then the test passes with JSON results:
    """
    {
        "document": {
            "should respond to #body": "PASSED"
        }
    }
    """
