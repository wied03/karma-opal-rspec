Feature: Source maps

  Background:
    Given the 'sourceMaps.js' Karma config file

  Scenario: Source map results
    Given the failure tests
    When I run the Karma test
    Then the test fails with JSON results:
      """
      {
          "something failure": {
              "should eq 43": "FAILED"
          }
      }
      """
    And the output should contain "webpack:///spec/main_spec.rb:5 in `(undefined)'"
