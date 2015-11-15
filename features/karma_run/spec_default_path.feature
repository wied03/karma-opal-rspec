Feature: Spec default paths

  Background:
    Given the 'defaultPath.js' Karma config file

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
