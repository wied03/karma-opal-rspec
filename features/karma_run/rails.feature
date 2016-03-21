Feature: Rails

  Background:
    Given the 'singlePattern.js' Karma config file

  Scenario: Rails specs js
    Given I copy spec/integration/rails_case/* to the working directory
    And I set the environment variable "RAILS_ENV" to "test"
    When I run the Karma test
    Then the test passes with JSON results:
    """
    {
        "ClassUnderTest ::howdy": {
            "should eq 42": "PASSED"
        },
        "GEM Pure JS": {
            "should include \"0.14\"": "PASSED"
        }
    }
    """
