Feature: Simple run

  Scenario: Stuff
    Given the 'karma.conf.js' Karma config file
    And the simple tests
    When I run the Karma test
    Then the test passes with JSON results:
    """
    {
        "something nested": {
            "should eq 42": "PASSED"
        }
    }
    """
