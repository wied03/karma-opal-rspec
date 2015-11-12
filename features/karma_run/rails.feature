Feature: Rails

  Background:
    Given the 'singlePattern.js' Karma config file

  Scenario: Rails specs js
    Given I copy spec/rails_case/* to the working directory
    When I run the Karma test
    Then the test passes with JSON results:
    """
    {
        "Bar": {
            "should eq 42": "PASSED"
        }
    }
    """
