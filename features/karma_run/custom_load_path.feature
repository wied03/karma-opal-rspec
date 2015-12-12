Feature: Custom load path

  Background:
    Given the 'customLoadPath.js' Karma config file

  Scenario: Basic
    Given the add_to_load_path/spec tests
    And I copy spec/integration/add_to_load_path/src_dir to the working directory
    When I run the Karma test
    Then the test passes with JSON results:
    """
    {
        "ClassUnderTest nested": {
            "should eq 42": "PASSED"
        }
    }
    """
