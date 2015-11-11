Feature: Simple run

  @announce-output @announce-command
  Scenario: Stuff
    Given the 'karma.conf.js' Karma config file
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
