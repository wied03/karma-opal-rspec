Feature: Specify roll up

  Background:
    Given the 'rollUp.js' Karma config file

  Scenario: Basic
    Given the ruby_require tests
    When I run the Karma test
    Then the test passes with JSON results:
    """
    {
        "Foo": {
            "should eq 42": "PASSED"
        }
    }
    """
