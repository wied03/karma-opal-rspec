Feature: Spec default paths

  Background:
    Given the 'defaultPath.js' Karma config file
    And I set the environment variable "RAILS_ENV" to ""

  Scenario: Basic
    Given the default_path tests
    When I run the Karma test
    Then the test passes with JSON results:
    """
    {
        "Foo nested": {
            "should eq 42": "PASSED"
        }
    }
    """
