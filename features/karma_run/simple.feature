Feature: Simple run

  Scenario: Stuff
    Given the 'karma.conf.js' Karma config file
    And the simple tests
    When I run the Karma test
    Then the exit status should be 0
    And the results should be:
    """
    {
        "something nested": {
            "should eq 42": "PASSED"
        }
    }
    """
