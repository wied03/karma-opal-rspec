Feature: Run Karma Tests

  Scenario: No requires, passing
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

  Scenario: Sprockets require
    Given the 'karma.conf.js' Karma config file
    And the sprockets_require tests
    When I run the Karma test
    Then the test passes with JSON results:
    """
    {
        "something via sprockets": {
            "should eq 22": "PASSED"
        }
    }
    """

  Scenario: Ruby require
    Given the 'karma.conf.js' Karma config file
    And the ruby_require tests
    When I run the Karma test
    Then the test passes with JSON results:
    """
    {
        "Foo": {
            "should eq 42": "PASSED"
        }
    }
    """
