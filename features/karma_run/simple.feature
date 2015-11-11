Feature: Run Karma Tests

  Background:
    Given the 'karma.conf.js' Karma config file

  Scenario: No requires, passing
    Given the simple tests
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
    Given the sprockets_require tests
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

  Scenario: Failed test
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
