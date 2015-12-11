Feature: Specify roll up

  Background:
    Given the 'rollUp.js' Karma config file
    And I set the environment variable "RAILS_ENV" to ""

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
