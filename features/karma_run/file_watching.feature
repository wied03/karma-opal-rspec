Feature: Watch files

  Background:
    Given the 'singlePattern.js' Karma config file

  Scenario: New spec added
    Given the simple tests
    And I run the Karma test and keep Karma running
    And the test passes with JSON results:
    """
    {
        "something nested": {
            "should eq 42": "PASSED"
        }
    }
    """
    When I add a new spec file and wait
    Then the test passes with JSON results:
    """
    {
        "something nested": {
            "should eq 42": "PASSED"
        },
        "else": {
          "should eq 43": "PASSED"
        }
    }
    """

  Scenario: New spec and dependency added
    Given a complete scenario

  Scenario: File changes without dependency change
    Given a complete scenario

  Scenario: File changes with dependency change
    Given a complete scenario

  Scenario: File removed
    Given a complete scenario
