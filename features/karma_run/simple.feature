Feature: Simple run
  Scenario: Stuff
    Given I run `./node_modules/karma/bin/karma start --single-run`
    Then the exit status should be 0
    And the output should contain:
    """
    foo
    """
