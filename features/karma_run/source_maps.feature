Feature: Source maps

  Background:
    Given the 'sourceMaps.js' Karma config file

  Scenario: Pure Opal
    Given the simple tests
    When I run the Karma test and keep Karma running
    Then the test passes with JSON results:
    """
    {
        "something nested": {
            "should eq 42": "PASSED"
        }
    }
    """
    And the following source maps exist:
      | File                    | Map URL          | Original File           | Sources                 |
      | /base/spec/main_spec.js | main_spec.js.map | /base/spec/main_spec.js | /base/spec/main_spec.rb |

  Scenario: Some JS files with no source maps
    Given the sprockets_require tests
    When I run the Karma test and keep Karma running
    Then the test passes with JSON results:
    """
    {
        "something via sprockets": {
            "should eq 22": "PASSED"
        }
    }
    """
    And we test the source map
